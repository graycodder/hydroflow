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
      // We need to fetch the current customer to know accurate balance? 
      // Multi-path updates are blind sets. We need usage of transactions (runTransaction) for counters.
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
        // If paymentMode is 'Credit', the customer owes this amount.
        // If 'Cash' or 'UPI', we assume it's paid instantly, so no change to debt.
        if (transaction.paymentMode == 'Credit') {
          double currentPending = (customerMap['pendingBalance'] as num?)?.toDouble() ?? 0.0;
          customerMap['pendingBalance'] = currentPending + transaction.amount;
        }
        
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
          logMap['cashCollected'] = currentCash + transaction.amount;
        } else if (transaction.paymentMode == 'Online' || transaction.paymentMode == 'UPI') {
          logMap['onlineCollected'] = currentOnline + transaction.amount;
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
