import 'package:hydroflow/features/bottles/domain/entities/salesman_bottle_ledger_stats.dart';
import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';

class GetSalesmanBottleLedgerUseCase {
  final CustomerRepository _customerRepository;
  final TransactionRepository _transactionRepository;
  final FirebaseDatabase _database;

  GetSalesmanBottleLedgerUseCase(
    this._customerRepository,
    this._transactionRepository,
    this._database,
  );

  Stream<SalesmanBottleLedgerStats> call(String salesmanId, DateTime date) {
    final customersStream = _customerRepository.getCustomers(salesmanId);
    final transactionsStream = _transactionRepository.getTransactionsByDate(salesmanId, date);
    
    final dateKey = date.toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    final logStream = logRef.onValue;

    // Fetch previous logs for carry-forward empty bottles
    final prevLogStream = _database.ref().child('Stock_logs').orderByChild('salesmanId').equalTo(salesmanId).onValue;
    
    // Fetch live salesman stock for absolute physical count
    final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
    final salesmanStream = salesmanRef.onValue;

    return Rx.combineLatest5(
      customersStream,
      transactionsStream,
      logStream,
      prevLogStream,
      salesmanStream,
      (customers, transactions, logEvent, prevLogEvent, salesmanEvent) {
        // 1. Calculate Customer Liability
        final activeCustomers = customers.where((c) => c.status == 'Active').toList();
        int totalWithCustomers = 0;
        int highBalanceCount = 0;
        
        for (var c in activeCustomers) {
          totalWithCustomers += c.bottleBalance;
          if (c.bottleBalance > 5) highBalanceCount++; // Threshold set to 5 for now
        }

        double avgBalance = activeCustomers.isEmpty ? 0 : totalWithCustomers / activeCustomers.length;

        // 2. Transaction Market Movement
        int deliveredToday = 0;
        int collectedToday = 0;
        
        for (var tx in transactions as List<TransactionEntity>) {
           deliveredToday += tx.cansDelivered.toInt();
           collectedToday += tx.emptyCollected.toInt();
        }

        // 3. Stock Logs Parsing (For Van Inventory)
        int loaded = 0;
        int logDelivered = 0;
        int logReturned = 0;
        int damaged = 0;
        int mismatchCount = 0;
        int emptyReturningToWarehouse = 0; 
        
        if (logEvent.snapshot.exists) {
           final data = Map<String, dynamic>.from(logEvent.snapshot.value as Map);
           loaded = (data['loaded'] as num?)?.toInt() ?? 0;
           logDelivered = (data['totalDelivered'] as num?)?.toInt() ?? 0;
           logReturned = (data['totalEmptyCollected'] as num?)?.toInt() ?? 0;
           damaged = (data['damaged'] as num?)?.toInt() ?? 0;
           mismatchCount = (data['mismatchCount'] as num?)?.toInt() ?? 0;
           emptyReturningToWarehouse = (data['unloadedEmpty'] as num?)?.toInt() ?? 0; // Assuming this field tracks warehouse drops
        }

        final effectiveDelivered = deliveredToday > 0 ? deliveredToday : logDelivered;
        final effectiveCollected = collectedToday;

        // 4. Trace Previous Day Empties (Carry Forward)
        int openingEmpties = 0;
        int openingFulls = 0;
        
        if (prevLogEvent.snapshot.exists) {
          final allLogs = Map<dynamic, dynamic>.from(prevLogEvent.snapshot.value as Map);
          final targetDateStr = date.toIso8601String().substring(0, 10);
          
          List<Map<String, dynamic>> sortedLogs = [];
          allLogs.forEach((key, value) {
            final log = Map<String, dynamic>.from(value as Map);
            if (log['date'] != null && (log['date'] as String).compareTo(targetDateStr) < 0) {
              sortedLogs.add(log);
            }
          });

          if (sortedLogs.isNotEmpty) {
             sortedLogs.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
             final mostRecentLog = sortedLogs.first;
             
             // The empties remaining from yesterday: (What they had) - (What they returned to warehouse)
             // This highly depends on your previous logging schema. If not explicit, we estimate based on mismatch vs collected.
             openingEmpties = (mostRecentLog['closingEmptyBottles'] as num?)?.toInt() ?? 0;
             openingFulls = (mostRecentLog['actualClosingStock'] as num?)?.toInt() ?? 
                            (mostRecentLog['closingStock'] as num?)?.toInt() ?? 0;
          }
        }

        // 5. Live Physical Flow
        int currentFull = 0;
        if (salesmanEvent.snapshot.exists) {
           final data = Map<String, dynamic>.from(salesmanEvent.snapshot.value as Map);
           currentFull = (data['currentStock'] as num?)?.toInt() ?? 0;
        }

        int currentEmpties = (openingEmpties + effectiveCollected) - emptyReturningToWarehouse;

        return SalesmanBottleLedgerStats(
          openingEmptyBottles: openingEmpties,
          fullBottlesLoaded: loaded,
          emptyBottlesReturnedToWarehouse: emptyReturningToWarehouse,
          currentPhysicalEmptyCount: currentEmpties < 0 ? 0 : currentEmpties, // prevent negative UI
          currentPhysicalFullCount: currentFull,
          bottlesDeliveredToday: effectiveDelivered,
          bottlesCollectedToday: effectiveCollected,
          netMarketMovement: effectiveDelivered - effectiveCollected,
          totalBottlesWithCustomers: totalWithCustomers,
          highBalanceCount: highBalanceCount,
          averageCustomerHolding: avgBalance,
          customers: activeCustomers,
          damagedBottles: damaged,
          mismatchCount: mismatchCount,
          todayTransactions: transactions,
        );
      }
    );
  }
}
