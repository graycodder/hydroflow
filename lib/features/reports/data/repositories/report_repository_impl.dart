import 'package:firebase_database/firebase_database.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';
import 'package:hydroflow/features/reports/domain/repositories/report_repository.dart';
import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

class ReportRepositoryImpl implements ReportRepository {
  final FirebaseDatabase _database;
  final TransactionRepository _transactionRepository;
  final CustomerRepository _customerRepository;

  ReportRepositoryImpl({
    required FirebaseDatabase database,
    required TransactionRepository transactionRepository,
    required CustomerRepository customerRepository,
  })  : _database = database,
        _transactionRepository = transactionRepository,
        _customerRepository = customerRepository;

  @override
  Stream<ReportEntity> getDailyReport(String salesmanId, DateTime date) {
    final transactionsStream = _transactionRepository.getTransactionsByDate(salesmanId, date);
    final customersStream = _customerRepository.getCustomers(salesmanId);
    
    final dateKey = date.toIso8601String().substring(0, 10).replaceAll('-', '_');
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');
    final logStream = logRef.onValue;

    final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
    final salesmanStream = salesmanRef.onValue;

    // Fetch previous day's log for carry forward
    final prevDate = date.subtract(Duration(days: 1));
    final prevDateKey = prevDate.toIso8601String().substring(0, 10).replaceAll('-', '_');
    final prevLogRef = _database.ref().child('Stock_logs').child('LOG_${prevDateKey}_$salesmanId');
    final prevLogStream = prevLogRef.onValue;

    return Rx.combineLatest5<List<TransactionEntity>, List<Customer>, DatabaseEvent, DatabaseEvent, DatabaseEvent, ReportEntity>(
      transactionsStream,
      customersStream,
      logStream,
      salesmanStream,
      prevLogStream,
      (transactions, customers, logEvent, salesmanEvent, prevLogEvent) {
        // 1. Calculate Bottle Balance from Customers
        // Logic deferred to use snapshot if available.
        // Also filter customers who did not exist on this date to improve accuracy of fallback.
        final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
        final relevantCustomers = customers.where((c) {
          if (c.createdAt == null) return true; // Legacy customers included
          return c.createdAt!.isBefore(dayEnd);
        }).toList();


        // 2. Parse Stock Logs
        int openingStock = 0;
        int loaded = 0;
        int damaged = 0;
        int stockMismatch = 0;
        
        // Snapshot Support
        int? snapshotTotalBottles;

        // Determine Opening Stock from Previous Day Closing if available
        int carriedForwardOpening = 0;
        if (prevLogEvent.snapshot.exists) {
           final prevData = Map<String, dynamic>.from(prevLogEvent.snapshot.value as Map);
           carriedForwardOpening = (prevData['closingStock'] as num?)?.toInt() ?? 0;
        }
        
        if (logEvent.snapshot.exists) {
          final data = Map<String, dynamic>.from(logEvent.snapshot.value as Map);
          openingStock = (data['openingStock'] as num?)?.toInt() ?? 0;
          loaded = (data['loaded'] as num?)?.toInt() ?? 0;
          damaged = (data['damaged'] as num?)?.toInt() ?? 0;
          stockMismatch = (data['mismatchCount'] as num?)?.toInt() ?? 0;
          
          if (data.containsKey('totalBottlesWithCustomers')) {
            snapshotTotalBottles = (data['totalBottlesWithCustomers'] as num?)?.toInt();
          }
          
          // Bug Fix: If opening stock is 0 but we have a valid carry forward, use it.
          // This fixes the specific issue user reported.
          if (openingStock == 0 && carriedForwardOpening > 0) {
            openingStock = carriedForwardOpening;
          }
        } else {
          // If no log for today yet, assume opening is carry forward
          openingStock = carriedForwardOpening;
        }

        // 3. Parse Salesman Data
        int currentStock = 0;
        double totalDepositsHeld = 0.0;
        if (salesmanEvent.snapshot.exists) {
          final data = Map<String, dynamic>.from(salesmanEvent.snapshot.value as Map);
          currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
          totalDepositsHeld = (data['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0;
        }

        // 4. Calculate Aggregate Metrics from Transactions
        double salesRevenue = 0; 
        double totalCollected = 0; 
        double totalCreditPending = 0; 
        double cashSales = 0; 
        double onlineSales = 0; 
        double securityDepositsCollected = 0;
        double securityDepositsRefunded = 0;
        double cashFromDeposits = 0;
        double onlineFromDeposits = 0;
        double securityDepositsRefundedCash = 0;
        double securityDepositsRefundedOnline = 0;
        int delivered = 0;
        int returned = 0;
        
        for (var tx in transactions) {
          final isCash = tx.paymentMode == 'Cash';
          final isOnline = tx.paymentMode == 'Online' || tx.paymentMode == 'UPI';

          if (tx.type == 'Deposit') {
            securityDepositsCollected += tx.amountReceived;
            totalCollected += tx.amountReceived;
            if (isCash) {
              cashFromDeposits += tx.amountReceived;
            } else if (isOnline) {
              onlineFromDeposits += tx.amountReceived;
            }
            continue; 
          } else if (tx.type == 'Refund') {
             securityDepositsRefunded += tx.amountReceived;
             totalCollected -= tx.amountReceived;
             if (isCash) {
               securityDepositsRefundedCash += tx.amountReceived;
             } else if (isOnline) {
               securityDepositsRefundedOnline += tx.amountReceived;
             }
             continue; 
          }

          salesRevenue += tx.amount;
          if (tx.paymentMode != 'Deposit Adjustment') {
            totalCollected += tx.amountReceived;
          }
          totalCreditPending += (tx.amount - tx.amountReceived);
          
          if (tx.paymentMode == 'Cash') {
            cashSales += tx.amountReceived; 
          } else if (tx.paymentMode == 'Online' || tx.paymentMode == 'UPI') {
            onlineSales += tx.amountReceived;
          }
          
          delivered += tx.cansDelivered.toInt();
          returned += tx.emptyCollected.toInt();
        }
        
        // 5. Stock Reconciliation
        // Use our corrected openingStock
        final finalOpening = openingStock;
        final finalAvailable = finalOpening + loaded;
        final calculatedClosing = finalAvailable - delivered - damaged;
        
        // If log exists, closingStock is usually what's in there, but if we corrected opening,
        // we should probably trust our calculated closing for consistency in the report view.
        // We calculate closing to ensure Opening + Loaded - Delivered = Closing consistency.
        final finalClosing = calculatedClosing;
        final netDeposits = securityDepositsCollected - securityDepositsRefunded;
        final cashInHand = cashSales + cashFromDeposits - securityDepositsRefunded;
        final upiCollections = onlineSales + onlineFromDeposits;
        final avgPrice = delivered > 0 ? salesRevenue / delivered : 0.0;
        final turnover = finalAvailable > 0 ? (delivered / finalAvailable) * 100 : 0.0;

        return ReportEntity(
          date: date,
          totalRevenue: salesRevenue, 
          totalDeliveries: delivered,
          openingStock: finalOpening,
          stockLoaded: loaded,
          totalAvailable: finalAvailable,
          deliveredStock: delivered,
          damagedStock: damaged,
          closingStock: finalClosing,
          stockMismatch: stockMismatch,
          bottlesDelivered: delivered,
          bottlesReturned: returned,
          netBottlesOut: delivered - returned,
          totalBottlesWithCustomers: snapshotTotalBottles ?? relevantCustomers.fold(0, (sum, c) => sum + c.bottleBalance),
          salesRevenue: salesRevenue,
          totalCollected: totalCollected,
          totalCreditPending: totalCreditPending,
          cashSales: cashSales,
          onlineSales: onlineSales,
          securityDepositsCollected: securityDepositsCollected,
          securityDepositsCollectedCash: cashFromDeposits,
          securityDepositsCollectedOnline: onlineFromDeposits,
          securityDepositsRefunded: securityDepositsRefunded,
          securityDepositsRefundedCash: securityDepositsRefundedCash,
          securityDepositsRefundedOnline: securityDepositsRefundedOnline,
          netDeposits: netDeposits,
          totalDepositsHeld: totalDepositsHeld,
          cashInHand: cashInHand,
          upiCollections: upiCollections,
          avgPricePerCan: avgPrice,
          stockTurnover: turnover,
          totalCustomers: relevantCustomers.length,
          activeCustomers: 0,
          newCustomers: 0,
          inactiveCustomers: 0,
        );
      },
    );
  }

  @override
  Stream<ReportEntity> getMonthlyReport(String salesmanId, DateTime month) {
    final transactionsStream = _transactionRepository.getTransactionsByMonth(salesmanId, month);
    final customersStream = _customerRepository.getCustomers(salesmanId);
    
    final logsStream = _database.ref()
        .child('Stock_logs')
        .orderByChild('salesmanId')
        .equalTo(salesmanId)
        .onValue;

    final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
    final salesmanStream = salesmanRef.onValue;

    return Rx.combineLatest4<List<TransactionEntity>, List<Customer>, DatabaseEvent, DatabaseEvent, ReportEntity>(
      transactionsStream,
      customersStream,
      logsStream,
      salesmanStream,
      (transactions, customers, logsEvent, salesmanEvent) {
        // 1. Filter Customers based on creation date
        // Customers created AFTER this month should not be counted in stats for this month
        final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
        final relevantCustomers = customers.where((c) {
          if (c.createdAt == null) return true; // Legacy customers are always included
          return c.createdAt!.isBefore(monthEnd);
        }).toList();

        // 2. Bottle Balance from RELEVANT Customers
        // Note: Bottle balance is current state, so it might be slightly off for past reports 
        // if user history isn't perfect, but we can't easily reconstruction past bottle balance without full replay.
        // For now, using current balance of relevant customers is the best approximation.
        final totalBottlesWithCustomers = relevantCustomers.fold(0, (sum, c) => sum + c.bottleBalance);

        // 3. Aggregate Stock Logs for the month
        int totalLoaded = 0;
        int totalDamaged = 0;
        int totalMismatch = 0;
        int monthlyOpeningStock = 0;
        bool hasOpeningStock = false;
        
        final monthPrefix = month.toIso8601String().substring(0, 7).replaceAll('-', '_');

        if (logsEvent.snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(logsEvent.snapshot.value as Map);
          
          // Sort logs by date to find the earliest one for opening stock
          final sortedKeys = data.keys.where((k) => k.toString().contains(monthPrefix)).toList();
          sortedKeys.sort(); // String sort works for 'LOG_YYYY_MM_DD' format

          if (sortedKeys.isNotEmpty) {
             final firstLog = Map<String, dynamic>.from(data[sortedKeys.first] as Map);
             monthlyOpeningStock = (firstLog['openingStock'] as num?)?.toInt() ?? 0;
             hasOpeningStock = true;
          }

          data.forEach((key, value) {
            if (key.toString().contains(monthPrefix)) {
              final log = Map<String, dynamic>.from(value as Map);
              totalLoaded += (log['loaded'] as num?)?.toInt() ?? 0;
              totalDamaged += (log['damaged'] as num?)?.toInt() ?? 0;
              totalMismatch += (log['mismatchCount'] as num?)?.toInt() ?? 0;
            }
          });
        }

        // 3. Parse Salesman Data
        int currentStock = 0;
        double totalDepositsHeld = 0.0;
        if (salesmanEvent.snapshot.exists) {
          final data = Map<String, dynamic>.from(salesmanEvent.snapshot.value as Map);
          currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
          totalDepositsHeld = (data['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0;
        }

        // 4. Aggregate Metrics from Transactions
        double salesRevenue = 0;
        double totalCollected = 0;
        double totalCreditPending = 0;
        double cashSales = 0;
        double onlineSales = 0;
        double securityDepositsCollected = 0;
        double securityDepositsRefunded = 0;
        double cashFromDeposits = 0;
        double onlineFromDeposits = 0;
        double securityDepositsRefundedCash = 0;
        double securityDepositsRefundedOnline = 0;
        int delivered = 0;
        int returned = 0;

        for (var tx in transactions) {
          final isCash = tx.paymentMode == 'Cash';
          final isOnline = tx.paymentMode == 'Online' || tx.paymentMode == 'UPI';

          if (tx.type == 'Deposit') {
            securityDepositsCollected += tx.amountReceived;
            totalCollected += tx.amountReceived;
            if (isCash) {
              cashFromDeposits += tx.amountReceived;
            } else if (isOnline) {
              onlineFromDeposits += tx.amountReceived;
            }
            continue;
          } else if (tx.type == 'Refund') {
            securityDepositsRefunded += tx.amountReceived;
            totalCollected -= tx.amountReceived;
            if (isCash) {
              securityDepositsRefundedCash += tx.amountReceived;
            } else if (isOnline) {
              securityDepositsRefundedOnline += tx.amountReceived;
            }
            continue;
          }

          salesRevenue += tx.amount;
          if (tx.paymentMode != 'Deposit Adjustment') {
            totalCollected += tx.amountReceived;
          }
          totalCreditPending += (tx.amount - tx.amountReceived);
          
          if (tx.paymentMode == 'Cash') {
            cashSales += tx.amountReceived;
          } else if (tx.paymentMode == 'Online' || tx.paymentMode == 'UPI') {
            onlineSales += tx.amountReceived;
          }
          
          delivered += tx.cansDelivered.toInt();
          returned += tx.emptyCollected.toInt();
        }

        // 5. Financials & Stock Reconciliation
        final netDeposits = securityDepositsCollected - securityDepositsRefunded;
        final cashInHand = cashSales + cashFromDeposits - securityDepositsRefunded;
        final upiCollections = onlineSales + onlineFromDeposits;
        final avgPrice = delivered > 0 ? salesRevenue / delivered : 0.0;

        // Logic Change: Only use currentStock for the current month.
        // For past months, rely on logs or defaults to avoid showing current data in empty past reports.
        final now = DateTime.now();
        final isCurrentMonth = month.year == now.year && month.month == now.month;

        int calculatedOpening = 0;
        int calculatedClosing = 0;

        if (isCurrentMonth) {
          calculatedOpening = hasOpeningStock 
              ? monthlyOpeningStock 
              : (currentStock + delivered + totalDamaged - totalLoaded);
          calculatedClosing = currentStock;
        } else {
          // Past month: Do not use currentStock
          calculatedOpening = hasOpeningStock ? monthlyOpeningStock : 0;
          calculatedClosing = calculatedOpening + totalLoaded - delivered - totalDamaged;
        }

        // Safety clamp
        if (calculatedOpening < 0) calculatedOpening = 0;
        if (calculatedClosing < 0) calculatedClosing = 0;
            
        final totalAvailable = calculatedOpening + totalLoaded;
        final turnover = totalAvailable > 0 ? (delivered / totalAvailable) * 100 : 0.0;

        // 6. Customer Stats & Daily Averages
        final activeCustomerIds = transactions.map((t) => t.customerId).toSet();
        final workingDaysList = transactions.map((t) => 
          DateTime(t.timestamp.year, t.timestamp.month, t.timestamp.day)
        ).toSet();
        final workingDaysCount = workingDaysList.length;
        final avgDailyRev = workingDaysCount > 0 ? (salesRevenue + netDeposits) / workingDaysCount : 0.0;
        final avgDailyDel = workingDaysCount > 0 ? delivered.toDouble() / workingDaysCount : 0.0;

        return ReportEntity(
          date: month,
          totalRevenue: salesRevenue + netDeposits,
          totalDeliveries: delivered,
          openingStock: calculatedOpening,
          stockLoaded: totalLoaded,
          totalAvailable: totalAvailable,
          deliveredStock: delivered,
          damagedStock: totalDamaged,
          closingStock: calculatedClosing,
          stockMismatch: totalMismatch,
          bottlesDelivered: delivered,
          bottlesReturned: returned,
          netBottlesOut: delivered - returned,
          totalBottlesWithCustomers: totalBottlesWithCustomers,
          salesRevenue: salesRevenue,
          totalCollected: totalCollected,
          totalCreditPending: totalCreditPending,
          cashSales: cashSales,
          onlineSales: onlineSales,
          securityDepositsCollected: securityDepositsCollected,
          securityDepositsCollectedCash: cashFromDeposits,
          securityDepositsCollectedOnline: onlineFromDeposits,
          securityDepositsRefunded: securityDepositsRefunded,
          securityDepositsRefundedCash: securityDepositsRefundedCash,
          securityDepositsRefundedOnline: securityDepositsRefundedOnline,
          netDeposits: netDeposits,
          totalDepositsHeld: totalDepositsHeld,
          cashInHand: cashInHand,
          upiCollections: upiCollections,
          avgPricePerCan: avgPrice,
          stockTurnover: turnover,
          workingDays: workingDaysCount,
          avgDailyRevenue: avgDailyRev,
          avgDailyDeliveries: avgDailyDel,
          totalCustomers: relevantCustomers.length,
          activeCustomers: activeCustomerIds.length,
          inactiveCustomers: relevantCustomers.length - activeCustomerIds.length,
          newCustomers: 0, 
        );
      },
    );
  }
}
