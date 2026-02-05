import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hydroflow/features/transactions/data/models/transaction_model.dart';
import 'package:hydroflow/features/customers/data/models/customer_model.dart'; // Needed to fetch/update customer
import 'package:hydroflow/features/auth/data/models/salesman_model.dart'; // Needed to fetch/update salesman

class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseDatabase _database;

  TransactionRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Future<void> recordTransaction(TransactionEntity transaction) async {
    try {
      // 1. Record Transaction
      final txRef = _database.ref().child('Transactions').push();
      final txModel = TransactionModel(
        id: txRef.key!,
        salesmanId: transaction.salesmanId,
        customerId: transaction.customerId,
        timestamp: transaction.timestamp,
        type: transaction.type,
        amount: transaction.amount,
        amountReceived: transaction.amountReceived,
        paymentMode: transaction.paymentMode,
        cansDelivered: transaction.cansDelivered,
        emptyCollected: transaction.emptyCollected,
        notes: transaction.notes,
      );
      
      // Update data atomically if possible, but RTDB multi-path updates can be tricky with complex logic.
      // For simplicity/safety, we'll do sequential updates, or try a multi-path update map.
      // Let's use a multi-path update for atomicity.
      
      final Map<String, dynamic> updates = {};
      
      // Add transaction
      updates['/Transactions/${txRef.key}'] = txModel.toMap();

      // 2. Prepare Customer Update
      // Logic Change for Partial Payment:
      // The Customer OWEs (Debt increases by) = Bill Amount - Amount Received.
      // Example: Bill 600, Paid 300 -> Debt +300.
      // Example: Bill 600, Paid 600 -> Debt +0.
      // Example: Bill 600, Paid 0 -> Debt +600.
      
      // Also for "Pure Collection" (0 cans, Bill 300, Paid 300):
      // If Bill is technically 0? No, usually Bill is amount user enters.
      // Wait. If "Pure Collection", user enters "Amount: 300".
      // UI: Total = 300. Received = 300.
      // Debt Change = 300 - 300 = 0? NO.
      // Pure Collection reduces debt.
      // Logic needs to distinguish "Sale" vs "Collection".
      // Or we just trust the math?
      // Net Change = (Value of Goods Delivered) - (Amount Paid).
      // But we track Value of Goods via `amount`?
      // In "Pure Collection", `cansDelivered` is 0. `amount` entered is "Amount".
      // Usually `amount` represents "Value of this Transaction".
      // If it's a collection, Value is 0 (no goods). But `amount` field stores the money involved.
      // Let's stick to the previous robust logic but adapt for Partial.
      
      // REVISED LOGIC:
      // We rely on `transaction.amount` acting as "Total Bill Value" and `transaction.amountReceived` as "Payment".
      // EXCEPT for "Pure Collection".
      // To simplify, let's treat:
      // Increase in Debt = (Value of Goods) - (Amount Received).
      // If Cans > 0: Value of Goods = transaction.amount.
      // If Cans == 0 (Collection): Value of Goods = 0.
      //   -> Debt Change = 0 - Amount Received. (Correctly reduces debt!)
      // THIS WORKS FOR ALL CASES!
      
      // But wait, `transaction.amount` in UI comes from `_priceController`.
      // If I return 0 cans, and enter "300" in Price, that usually means "I am collecting 300".
      // If I treat `transaction.amount` as "Value of Goods", then for Collection, `transaction.amount` should ideally be 0?
      // But existing UI uses `amount` to store the collection amount.
      
      // Let's refine:
      // 1. Sale (Cans > 0): 
      //    Val = transaction.amount. 
      //    Paid = transaction.amountReceived.
      //    Debt += Val - Paid.
      // 2. Collection (Cans == 0):
      //    Val = 0.
      //    Paid = transaction.amountReceived.
      //    Debt += 0 - Paid. (Reduces debt).
      
      // Does this hold? 
      // If I deliver 10 cans (600), Pay 300.
      // Val = 600. Paid = 300. Debt += 300. (Correct).
      
      // If I Collect 300.
      // UI: Cans = 0. Price = 300. Amount Rec = 300.
      // Val = 0. Paid = 300. Debt -= 300. (Correct).
      
      // What if "Credit Collection"? (I collect 0?) -> No, that's just nothing.
      
      // So key is: `transaction.amount` is "Bill Total".
      // If Cans > 0, "Bill Total" == "Goods Value".
      // If Cans == 0, "Bill Total" is just... the amount field. 
      // Actually, if Cans == 0, "Price" field is effectively "Amount Collected".
      // BUT `amountReceived` is now the explicit "Amount Collected" field.
      // So for Collection:
      // User enters: Cans=0. Price=300? No, maybe Price field is confusing if it's not "Goods Value".
      // If Cans=0, Price should ideally be 0?
      // If our UI binds Price to 300 for collection, we have a terminology clash.
      
      // Let's look at `DeliveryPage`.
      // User enters Price manually.
      // For Collection: They enter Price = 300.
      // Auto-fill makes AmountReceived = 300.
      // So `amount`=300, `amountReceived`=300.
      
      // If we use logic `Debt += (Cans > 0 ? amount : 0) - amountReceived`:
      // Collection: Debt += 0 - 300 = -300. (Correct).
      // Sale: Debt += 600 - 300 = +300. (Correct).
      
      // What if I mistakenly enter Price=300 for Collection, but set Amount Received = 0 (Credit)?
      // Cans=0. Price=300. Rec=0.
      // Debt += 0 - 0 = 0. (Nothing happens). Correct.
      // But `transaction.amount` (300) is stored in log. What does it mean? "Bill Value 300"? For 0 cans?
      // Ideally for Collection, `amount` (Bill Value) SHOULD be 0.
      
      // Let's enforce in Repository:
      // effectiveBillValue = (transaction.cansDelivered > 0) ? transaction.amount : 0.0;
      // balanceChange = effectiveBillValue - transaction.amountReceived;
      
      // Since we touch multiple nodes (Transactions, Customers, Salesmen), a single runTransaction is hard.
      // We will assume "optimistic" flow or sequential reads.
      // Because we need to READ the current balance to ADD to it, we should use runTransaction on specific nodes.
      
      // However, to keep it simple and robust enough for this MVP:
      // We will perform actions sequentially. If one fails, we might have inconsistency, but strictly locked transactions are complex.
      // Actually, let's use `runTransaction` for the sensitive counter updates.

      // A. Save Transaction Log (Safe to do anytime)
      await txRef.set(txModel.toMap());

      // B. Update Customer Balance 
      final customerRef = _database.ref().child('Customers/${transaction.customerId}');
      await customerRef.runTransaction((Object? post) {
        if (post == null) {
          return Transaction.abort();
        }
        final customerMap = Map<String, dynamic>.from(post as Map);
        
        // Update Bottle Balance
        // Delivered (+), Collected (-)
        // Wait, Bottle Balance = "bottles with customer". 
        // So Delivered increases balance (+), Collected decreases balance (-).
        int currentBottleBalance = (customerMap['bottleBalance'] as num?)?.toInt() ?? 0;
        customerMap['bottleBalance'] = currentBottleBalance + transaction.cansDelivered - transaction.emptyCollected;

        // Update Pending Balance (Money)
        double currentPending = (customerMap['pendingBalance'] as num?)?.toDouble() ?? 0.0;
        
        // Logic: Balance += (Value of Goods - Amount Sent/Received)
        // If delivery (cans > 0), Value = Amount.
        // If collection only (cans == 0), Value = 0 (we ignore the 'amount' field as bill value).
        
        final double effectiveBillValue = (transaction.cansDelivered > 0 || transaction.emptyCollected > 0) 
            ? transaction.amount 
            : 0.0; 
            
        // Wait, if I return bottles (emptyCollected > 0) and NO delivery?
        // Usually that's 0 value unless we refund?
        // Let's assume `amount` entered by user IS the Bill Value.
        // User is responsible for entering correct Bill Value.
        // If Cans=10, Price=600. Bill=600.
        // If Cans=0, Price=300 (Collection?). 
        // IF IT IS A COLLECTION, the Bill Value (Goods Sold) is 0.
        // But the user entered 300 in Price field.
        
        // Let's stick to strict logic:
        // Sales (Cans > 0): Goods Value = amount.
        // No Sales (Cans = 0): Goods Value = 0.
        
        final double goodsValue = (transaction.cansDelivered > 0) ? transaction.amount : 0.0;
        final double amountPaid = transaction.amountReceived;
        
        // Balance Change = Goods Value - Amount Paid
        customerMap['pendingBalance'] = currentPending + (goodsValue - amountPaid);
        
        return Transaction.success(customerMap);
      });

      // C. Update Salesman Inventory
      final salesmanRef = _database.ref().child('Salesmen/${transaction.salesmanId}');
      await salesmanRef.runTransaction((Object? post) {
        if (post == null) {
           return Transaction.abort();
        }
        final salesmanMap = Map<String, dynamic>.from(post as Map);
        
        // Decrease Full Cans (currentStock)
        int currentStock = (salesmanMap['currentStock'] as num?)?.toInt() ?? 0;
        salesmanMap['currentStock'] = currentStock - transaction.cansDelivered;
        
        // We could also track "Empty Bottles Held" by salesman if we want, but schema check required.
        // Salesman entity has `currentStock` (ints). Simple decrement.
        
        return Transaction.success(salesmanMap);
      });

      // D. Update Today's Stock Log
      final dateFormatted = transaction.timestamp.toIso8601String().substring(0, 10);
      final dateKey = dateFormatted.replaceAll('-', '_');
      final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_${transaction.salesmanId}');
      
      await logRef.update({
        'salesmanId': transaction.salesmanId,
        'date': dateFormatted,
      });

      await logRef.runTransaction((Object? post) {
        final logMap = post == null 
            ? <String, dynamic>{} 
            : Map<String, dynamic>.from(post as Map);
        
        final currentDelivered = (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
        final currentEmpty = (logMap['totalEmptyCollected'] as num?)?.toInt() ?? 0;
        final currentCash = (logMap['cashCollected'] as num?)?.toDouble() ?? 0.0;
        final currentOnline = (logMap['onlineCollected'] as num?)?.toDouble() ?? 0.0;

        logMap['totalDelivered'] = currentDelivered + transaction.cansDelivered;
        logMap['totalEmptyCollected'] = currentEmpty + transaction.emptyCollected;
        
        if (transaction.paymentMode == 'Cash') {
          logMap['cashCollected'] = currentCash + transaction.amountReceived;
        } else if (transaction.paymentMode == 'Online' || transaction.paymentMode == 'UPI') {
          logMap['onlineCollected'] = currentOnline + transaction.amountReceived;
        }

        return Transaction.success(logMap);
      });

    } catch (e) {
      throw Exception('Failed to record transaction: $e');
    }
  }

  @override
  Stream<List<TransactionEntity>> getTodayTransactions(String salesmanId) {
    final ref = _database.ref().child('Transactions');
    // We want transactions for THIS salesman.
    // We also want "Today".
    // RTDB filtering is limited. We usage onValue to listen to all updates for this salesman.
    
    return ref.orderByChild('salesmanId').equalTo(salesmanId).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<TransactionEntity> transactions = [];
        
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          final tx = TransactionModel.fromMap(map, key as String);
          
          if (tx.timestamp.isAfter(startOfDay) && tx.timestamp.isBefore(endOfDay)) {
            transactions.add(tx);
          }
        });
        
        // Sort by timestamp desc
        transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return transactions;
      }
      return [];
    });
  }
}
