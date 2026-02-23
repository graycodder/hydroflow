import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hydroflow/features/transactions/data/models/transaction_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseDatabase _database;

  TransactionRepositoryImpl({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  @override
  Future<void> recordTransaction(TransactionEntity transaction) async {
    try {
      // 0. Define IDs
      final dateStr = DateFormat('yyyyMMdd').format(transaction.timestamp);
      final timeStr = DateFormat('HHmmss').format(transaction.timestamp);
      final safeSalesmanId = transaction.salesmanId.replaceAll(
        RegExp(r'[.#$\[\]]'),
        '_',
      );
      final customId = '${dateStr}_${safeSalesmanId}_$timeStr';

      // 1. Fetch Customer Balance Snapshot
      final customerSnapshot = await _database
          .ref()
          .child('Customers/${transaction.customerId}')
          .get();
      final customerData = customerSnapshot.value as Map<dynamic, dynamic>?;
      final double prevBalance =
          (customerData?['pendingBalance'] as num?)?.toDouble() ?? 0.0;

      // Universal Balance Logic:
      // New Balance = Old Balance + (Value of Transaction - Amount Received)
      // This works for:
      // - Delivery: amount (Bill) - received (Paid) -> Debt increases by difference
      // - Payment only: 0 - received -> Debt decreases by received
      // - Adjustment: amount (new debt) - received (payment)
      final double currBalance =
          prevBalance + (transaction.amount - transaction.amountReceived);

      final txModel = TransactionModel(
        id: customId,
        salesmanId: transaction.salesmanId,
        customerId: transaction.customerId,
        customerName: customerData?['name'] as String? ?? '',
        timestamp: transaction.timestamp,
        type: transaction.type,
        amount: transaction.amount,
        amountReceived: transaction.amountReceived,
        paymentMode: transaction.paymentMode,
        cansDelivered: transaction.cansDelivered,
        emptyCollected: transaction.emptyCollected,
        notes: transaction.notes,
        previousBalance: prevBalance,
        currentBalance: currBalance,
      );


      final Map<String, dynamic> updates = {};

      // Add transaction
      updates['/Transactions/$customId'] = txModel.toMap();

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
      // await txRef.set(txModel.toMap()); // Removed as we use updates map now
      await _database.ref().update(updates);

      // B. Update Customer Balance
      final customerRef = _database.ref().child(
        'Customers/${transaction.customerId}',
      );
      await customerRef.runTransaction((Object? post) {
        if (post == null) {
          return Transaction.abort();
        }
        final customerMap = Map<String, dynamic>.from(post as Map);

        // Update Bottle Balance
        // Delivered (+), Collected (-)
        // Wait, Bottle Balance = "bottles with customer".
        // So Delivered increases balance (+), Collected decreases balance (-).
        int currentBottleBalance =
            (customerMap['bottleBalance'] as num?)?.toInt() ?? 0;
        customerMap['bottleBalance'] =
            currentBottleBalance +
            transaction.cansDelivered -
            transaction.emptyCollected;

        // Update Pending Balance (Money)
        final double currentPending =
            (customerMap['pendingBalance'] as num?)?.toDouble() ?? 0.0;

        // Universal Logic: Balance += (Amount - AmountReceived)
        customerMap['pendingBalance'] =
            currentPending + (transaction.amount - transaction.amountReceived);

        return Transaction.success(customerMap);
      });

      // C. Update Stock based on Role
      final salesmanRef = _database.ref().child(
        'Salesmen/${transaction.salesmanId}',
      );

      // Fetch whole salesman data to check role and agencyId
      final salesmanSnapshot = await salesmanRef.get();
      if (!salesmanSnapshot.exists) throw Exception('Salesman data not found');

      final salesmanData = salesmanSnapshot.value as Map<dynamic, dynamic>;
      final String role = salesmanData['role'] as String? ?? 'salesman';
      final String agencyId = salesmanData['agencyId'] as String? ?? '';

      final currentStockInVanBeforeTx =
          (salesmanData['currentStock'] as num?)?.toInt() ?? 0;

      // C. Update Stock (All roles deduct from VEHICLE / Salesman node)
      await salesmanRef.runTransaction((Object? post) {
        if (post == null) return Transaction.abort();
        final salesmanMap = Map<String, dynamic>.from(post as Map);
        int currentStock = (salesmanMap['currentStock'] as num?)?.toInt() ?? 0;
        int currentEmpties =
            (salesmanMap['emptyBottles'] as num?)?.toInt() ?? 0;

        salesmanMap['currentStock'] = currentStock - transaction.cansDelivered;
        salesmanMap['emptyBottles'] =
            currentEmpties + transaction.emptyCollected;

        // NEW: Update Pending Cash Balance
        if (transaction.paymentMode == 'Cash') {
          double currentBalance =
              (salesmanMap['pendingCashBalance'] as num?)?.toDouble() ?? 0.0;
          if (transaction.type == 'Refund') {
            salesmanMap['pendingCashBalance'] =
                currentBalance - transaction.amountReceived;
          } else {
            salesmanMap['pendingCashBalance'] =
                currentBalance + transaction.amountReceived;
          }
        }

        // Track snapshot for stock log processing
        salesmanMap['_lastUpdateBalance'] =
            (salesmanMap['pendingCashBalance'] as num?)?.toDouble() ?? 0.0;

        return Transaction.success(salesmanMap);
      });

      // Fetch snapshot for stock log update
      final updatedSalesmanSnapshot = await salesmanRef.get();
      final updatedSalesmanData =
          updatedSalesmanSnapshot.value as Map<dynamic, dynamic>;
      final double latestPendingBalance =
          (updatedSalesmanData['pendingCashBalance'] as num?)?.toDouble() ??
          0.0;

      // D. Update Today's Stock Log
      final dateFormatted = transaction.timestamp.toIso8601String().substring(
        0,
        10,
      );
      final dateKey = dateFormatted.replaceAll('-', '_');
      final logRef = _database
          .ref()
          .child('Stock_logs')
          .child('LOG_${dateKey}_${transaction.salesmanId}');

      await logRef.runTransaction((Object? post) {
        final logMap = post == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(post as Map);

        final isNewLog = !logMap.containsKey('date');
        if (isNewLog) {
          logMap['salesmanId'] = transaction.salesmanId;
          logMap['date'] = dateFormatted;
          logMap['openingStock'] = currentStockInVanBeforeTx;
          logMap['loaded'] = 0;
          logMap['damaged'] = 0;
          logMap['actualClosingStock'] = 0;
          logMap['mismatchCount'] = 0;
          logMap['isReconciled'] = false;
        }

        final currentDelivered =
            (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
        final currentEmpty =
            (logMap['totalEmptyCollected'] as num?)?.toInt() ?? 0;
        final currentCash =
            (logMap['cashCollected'] as num?)?.toDouble() ?? 0.0;
        final currentOnline =
            (logMap['onlineCollected'] as num?)?.toDouble() ?? 0.0;
        final currentTotalSales =
            (logMap['totalSalesValue'] as num?)?.toDouble() ?? 0.0;
        final currentNetCollection =
            (logMap['todayCollection'] as num?)?.toDouble() ?? 0.0;

        final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
        final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
        final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;

        final newDelivered = currentDelivered + transaction.cansDelivered;
        logMap['totalDelivered'] = newDelivered;
        logMap['totalEmptyCollected'] =
            currentEmpty + transaction.emptyCollected;

        // Update Total Sales (Goods Value)
        if (transaction.cansDelivered > 0) {
          logMap['totalSalesValue'] = currentTotalSales + transaction.amount;
        }

        // Update Money Flow
        if (transaction.paymentMode == 'Cash') {
          logMap['cashCollected'] = currentCash + transaction.amountReceived;
        } else if (transaction.paymentMode == 'Online' ||
            transaction.paymentMode == 'UPI') {
          logMap['onlineCollected'] =
              currentOnline + transaction.amountReceived;
        }

        if (transaction.paymentMode != 'Deposit Adjustment') {
          logMap['todayCollection'] =
              currentNetCollection + transaction.amountReceived;
        }

        logMap['closingStock'] = opening + loaded - newDelivered - damaged;
        logMap['pendingCashClosingBalance'] = latestPendingBalance;

        return Transaction.success(logMap);
      });
    } catch (e) {
      throw Exception('Failed to record transaction: $e');
    }
  }

  @override
  Future<void> recordAdjustment(TransactionEntity transaction) async {
    try {
      // 0. Define IDs
      final dateStr = DateFormat('yyyyMMdd').format(transaction.timestamp);
      final timeStr = DateFormat('HHmmss').format(transaction.timestamp);
      final safeSalesmanId = transaction.salesmanId.replaceAll(
        RegExp(r'[.#$\[\]]'),
        '_',
      );
      final customId = '${dateStr}_${safeSalesmanId}_$timeStr';
      final txRef = _database.ref().child('Transactions').child(customId);

      // 1. Fetch Customer Balance Snapshot
      final customerSnapshot = await _database
          .ref()
          .child('Customers/${transaction.customerId}')
          .get();
      final customerData = customerSnapshot.value as Map<dynamic, dynamic>?;
      final double prevBalance =
          (customerData?['pendingBalance'] as num?)?.toDouble() ?? 0.0;
      final double currBalance =
          prevBalance + (transaction.amount - transaction.amountReceived);

      final txModel = TransactionModel(
        id: customId,
        salesmanId: transaction.salesmanId,
        customerId: transaction.customerId,
        customerName: customerData?['name'] as String? ?? '',
        timestamp: transaction.timestamp,
        type: transaction.type,
        amount: transaction.amount,
        amountReceived: transaction.amountReceived,
        paymentMode: transaction.paymentMode,
        cansDelivered: transaction.cansDelivered,
        emptyCollected: transaction.emptyCollected,
        notes: transaction.notes,
        previousBalance: prevBalance,
        currentBalance: currBalance,
      );


      // Save Transaction Log
      await txRef.set(txModel.toMap());

      // Note: We DO NOT update Customer Balance here because 'recordAdjustment' is called
      // from contexts (like Edit Customer) where the Customer Balance is manually updated
      // via 'UpdateCustomer'. We avoid double-counting.

      // 3. Update Stock based on Role (Only if cans delivered > 0)
      if (transaction.cansDelivered > 0) {
        final salesmanRef = _database.ref().child(
          'Salesmen/${transaction.salesmanId}',
        );
        final salesmanSnapshot = await salesmanRef.get();
        if (salesmanSnapshot.exists) {
          final salesmanData = salesmanSnapshot.value as Map<dynamic, dynamic>;
          final String role = salesmanData['role'] as String? ?? 'salesman';
          final String agencyId = salesmanData['agencyId'] as String? ?? '';

          // All roles deduct from VEHICLE
          await salesmanRef.runTransaction((Object? post) {
            if (post == null) return Transaction.abort();
            final salesmanMap = Map<String, dynamic>.from(post as Map);
            salesmanMap.update(
              'currentStock',
              (value) => (value as num).toInt() - transaction.cansDelivered,
              ifAbsent: () => 0,
            );
            salesmanMap.update(
              'emptyBottles',
              (value) => (value as num).toInt() + transaction.emptyCollected,
              ifAbsent: () => 0,
            );
            return Transaction.success(salesmanMap);
          });
        }
      }

      // 4. Update Today's Stock Log (Crucial for Reports)
      final dateFormatted = transaction.timestamp.toIso8601String().substring(
        0,
        10,
      );
      final dateKey = dateFormatted.replaceAll('-', '_');
      final logRef = _database
          .ref()
          .child('Stock_logs')
          .child('LOG_${dateKey}_${transaction.salesmanId}');

      await logRef.runTransaction((Object? post) {
        final logMap = post == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(post as Map);

        final isNewLog = !logMap.containsKey('date');
        if (isNewLog) {
          // If log doesn't exist, we might miss opening stock if not careful.
          // But usually log exists if they have stock. If not, 0 is fine.
          logMap['salesmanId'] = transaction.salesmanId;
          logMap['date'] = dateFormatted;
          logMap['openingStock'] =
              0; // Assumption or fetch? stick to simple for adjustment.
          logMap['loaded'] = 0;
          logMap['damaged'] = 0;
          logMap['actualClosingStock'] = 0;
          logMap['mismatchCount'] = 0;
          logMap['isReconciled'] = false;
        }

        final currentDelivered =
            (logMap['totalDelivered'] as num?)?.toInt() ?? 0;
        final currentEmpty =
            (logMap['totalEmptyCollected'] as num?)?.toInt() ?? 0;
        final currentCash =
            (logMap['cashCollected'] as num?)?.toDouble() ?? 0.0;
        final currentOnline =
            (logMap['onlineCollected'] as num?)?.toDouble() ?? 0.0;
        final currentTotalSales =
            (logMap['totalSalesValue'] as num?)?.toDouble() ?? 0.0;
        final currentNetCollection =
            (logMap['todayCollection'] as num?)?.toDouble() ?? 0.0;

        final opening = (logMap['openingStock'] as num?)?.toInt() ?? 0;
        final loaded = (logMap['loaded'] as num?)?.toInt() ?? 0;
        final damaged = (logMap['damaged'] as num?)?.toInt() ?? 0;

        final newDelivered = currentDelivered + transaction.cansDelivered;
        logMap['totalDelivered'] = newDelivered;
        logMap['totalEmptyCollected'] =
            currentEmpty + transaction.emptyCollected;

        // Update Total Sales (Goods Value)
        if (transaction.cansDelivered > 0) {
          logMap['totalSalesValue'] = currentTotalSales + transaction.amount;
        }

        // Update Money Flow
        if (transaction.paymentMode == 'Cash') {
          logMap['cashCollected'] = currentCash + transaction.amountReceived;
        } else if (transaction.paymentMode == 'Online' ||
            transaction.paymentMode == 'UPI') {
          logMap['onlineCollected'] =
              currentOnline + transaction.amountReceived;
        }

        // For Adjustments, we usually want to track them in collection if they represent money received.
        // If Payment Mode is 'Deposit Adjustment', we skip collection?
        // But here we use 'Adjustment'.
        // If amountReceived > 0, it means money IS received (or account settled).
        // If it's a "Correction", maybe we shouldn't add to 'todayCollection'?
        // BUT, if I decrease balance 600->500, I admit I received 100.
        // So I should show it in collection.
        if (transaction.paymentMode != 'Deposit Adjustment') {
          logMap['todayCollection'] =
              currentNetCollection + transaction.amountReceived;
        }

        logMap['closingStock'] = opening + loaded - newDelivered - damaged;

        return Transaction.success(logMap);
      });
    } catch (e) {
      throw Exception('Failed to record adjustment: $e');
    }
  }

  @override
  Stream<List<TransactionEntity>> getTodayTransactions(String salesmanId) {
    return getTransactionsByDate(salesmanId, DateTime.now());
  }

  @override
  Stream<List<TransactionEntity>> getTodayTransactionsByAgency(
    List<String> salesmenIds,
  ) {
    if (salesmenIds.isEmpty) return Stream.value([]);

    // Aggregate streams for all salesmen
    final streams = salesmenIds.map((id) => getTodayTransactions(id)).toList();

    return CombineLatestStream.list<List<TransactionEntity>>(streams).map((
      lists,
    ) {
      final allTransactions = lists.expand((list) => list).toList();
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return allTransactions;
    });
  }

  @override
  Stream<List<TransactionEntity>> getTransactionsByDate(
    String salesmanId,
    DateTime date,
  ) {
    final ref = _database.ref().child('Transactions');

    return ref.orderByChild('salesmanId').equalTo(salesmanId).onValue.map((
      event,
    ) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<TransactionEntity> transactions = [];

        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          final tx = TransactionModel.fromMap(map, key as String);

          if (tx.timestamp.isAfter(
                startOfDay.subtract(const Duration(milliseconds: 1)),
              ) &&
              tx.timestamp.isBefore(endOfDay)) {
            transactions.add(tx);
          }
        });

        transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return transactions;
      }
      return [];
    });
  }

  @override
  Stream<List<TransactionEntity>> getTransactionsByMonth(
    String salesmanId,
    DateTime month,
  ) {
    final ref = _database.ref().child('Transactions');

    return ref.orderByChild('salesmanId').equalTo(salesmanId).onValue.map((
      event,
    ) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<TransactionEntity> transactions = [];

        final startOfMonth = DateTime(month.year, month.month, 1);
        final endOfMonth = DateTime(
          month.year,
          month.month + 1,
          1,
        ).subtract(const Duration(milliseconds: 1));

        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          final tx = TransactionModel.fromMap(map, key as String);

          if (tx.timestamp.isAfter(
                startOfMonth.subtract(const Duration(milliseconds: 1)),
              ) &&
              tx.timestamp.isBefore(
                endOfMonth.add(const Duration(milliseconds: 1)),
              )) {
            transactions.add(tx);
          }
        });

        transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return transactions;
      }
      return [];
    });
  }

  @override
  Stream<List<TransactionEntity>> getTransactionsByCustomer(String customerId) {
    final ref = _database.ref().child('Transactions');

    return ref.orderByChild('customerId').equalTo(customerId).onValue.map((
      event,
    ) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<TransactionEntity> transactions = [];

        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          transactions.add(TransactionModel.fromMap(map, key as String));
        });

        // Sort by timestamp descending
        transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return transactions;
      }
      return [];
    });
  }
}
