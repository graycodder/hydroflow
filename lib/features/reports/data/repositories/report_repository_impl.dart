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
        int logDelivered = 0;
        int damaged = 0;
        int stockMismatch = 0;
        
        // Snapshot Support
        int? snapshotTotalBottles;

        // Determine Opening Stock from Previous Day Closing if available
      int carriedForwardOpening = 0;
      if (prevLogEvent.snapshot.exists) {
         final prevData = Map<String, dynamic>.from(prevLogEvent.snapshot.value as Map);
         // PROPER FIX: Prioritize 'actualClosingStock' (physical count) over calculated 'closingStock'
         carriedForwardOpening = (prevData['actualClosingStock'] as num?)?.toInt() ?? 
                                 (prevData['closingStock'] as num?)?.toInt() ?? 0;
      }
        
        if (logEvent.snapshot.exists) {
          final data = Map<String, dynamic>.from(logEvent.snapshot.value as Map);
          openingStock = (data['openingStock'] as num?)?.toInt() ?? 0;
          loaded = (data['loaded'] as num?)?.toInt() ?? 0;
          logDelivered = (data['totalDelivered'] as num?)?.toInt() ?? 0;
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
        String salesmanName = "Unknown Salesman";

        if (salesmanEvent.snapshot.exists) {
          final data = Map<String, dynamic>.from(salesmanEvent.snapshot.value as Map);
          currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
          totalDepositsHeld = (data['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0;
          salesmanName = data['name'] as String? ?? "Unknown Salesman";
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
        // Use logDelivered if transactions are 0 (e.g. Agency warehouse transfers)
        final effectiveDelivered = delivered > 0 ? delivered : logDelivered;
        
        // 5. Stock Reconciliation
        // Use our corrected openingStock
        final finalOpening = openingStock;
        final finalAvailable = finalOpening + loaded;
        final calculatedClosing = finalAvailable - effectiveDelivered - damaged;
        
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
          deliveredStock: effectiveDelivered,
          damagedStock: damaged,
          closingStock: finalClosing,
          stockMismatch: stockMismatch,
          bottlesDelivered: effectiveDelivered,
          bottlesReturned: returned,
          netBottlesOut: effectiveDelivered - returned,
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
          salesmanId: salesmanId,
          salesmanName: salesmanName,
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
        int totalLogDelivered = 0;
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
              totalLogDelivered += (log['totalDelivered'] as num?)?.toInt() ?? 0;
              totalDamaged += (log['damaged'] as num?)?.toInt() ?? 0;
              totalMismatch += (log['mismatchCount'] as num?)?.toInt() ?? 0;
            }
          });
        }

        // 3. Parse Salesman Data
        int currentStock = 0;
        double totalDepositsHeld = 0.0;
        String salesmanName = "Unknown Salesman";

        if (salesmanEvent.snapshot.exists) {
          final data = Map<String, dynamic>.from(salesmanEvent.snapshot.value as Map);
          currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
          totalDepositsHeld = (data['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0;
          salesmanName = data['name'] as String? ?? "Unknown Salesman";
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

        final effectiveDelivered = delivered > 0 ? delivered : totalLogDelivered;

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
              : (currentStock + effectiveDelivered + totalDamaged - totalLoaded);
          calculatedClosing = currentStock;
        } else {
          // Past month: Do not use currentStock
          calculatedOpening = hasOpeningStock ? monthlyOpeningStock : 0;
          calculatedClosing = calculatedOpening + totalLoaded - effectiveDelivered - totalDamaged;
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
          deliveredStock: effectiveDelivered,
          damagedStock: totalDamaged,
          closingStock: calculatedClosing,
          stockMismatch: totalMismatch,
          bottlesDelivered: effectiveDelivered,
          bottlesReturned: returned,
          netBottlesOut: effectiveDelivered - returned,
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
          salesmanId: salesmanId,
          salesmanName: salesmanName,
        );
      },
    );
  }
  @override
  Stream<ReportEntity> getAgencyDailyReport(String agencyId, DateTime date) {
    // 1. Fetch all salesmen for the agency
    final agencySalesmenStream = _database
        .ref()
        .child('Salesmen')
        .orderByChild('agencyId')
        .equalTo(agencyId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final ids = data.keys.cast<String>().toList();
        ids.sort(); // Sort to ensure consistent comparison for distinct()
        return ids;
      }
      return <String>[];
    }).distinct((prev, curr) {
      if (prev.length != curr.length) return false;
      for (int i = 0; i < prev.length; i++) {
        if (prev[i] != curr[i]) return false;
      }
      return true;
    });

    return agencySalesmenStream.switchMap((salesmenIds) {
      if (salesmenIds.isEmpty) {
        return Stream.value(_emptyReport(date));
      }

      // 2. Create a stream of reports for EACH salesman + Warehouse
      final reportStreams = [
        getDailyReport(agencyId, date), // Warehouse Report
        ...salesmenIds.where((id) => id != agencyId).map((id) => getDailyReport(id, date)), // Salesmen Reports
      ];
      
      // 3. Combine and Aggregate
      return CombineLatestStream.list<ReportEntity>(reportStreams).map((reports) {
        return _aggregateReports(reports, date, agencyId: agencyId);
      });
    });
  }

  @override
  Stream<ReportEntity> getAgencyMonthlyReport(String agencyId, DateTime month) {
    final agencySalesmenStream = _database
        .ref()
        .child('Salesmen')
        .orderByChild('agencyId')
        .equalTo(agencyId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final ids = data.keys.cast<String>().toList();
        ids.sort(); // Sort to ensure consistent comparison for distinct()
        return ids;
      }
      return <String>[];
    }).distinct((prev, curr) {
      if (prev.length != curr.length) return false;
      for (int i = 0; i < prev.length; i++) {
        if (prev[i] != curr[i]) return false;
      }
      return true;
    });

    return agencySalesmenStream.switchMap((salesmenIds) {
      if (salesmenIds.isEmpty) {
        return Stream.value(_emptyReport(month));
      }

      final reportStreams = [
        getMonthlyReport(agencyId, month), // Warehouse Report
        ...salesmenIds.where((id) => id != agencyId).map((id) => getMonthlyReport(id, month)), // Salesmen Reports
      ];

      return CombineLatestStream.list<ReportEntity>(reportStreams).map((reports) {
        return _aggregateReports(reports, month, agencyId: agencyId);
      });
    });
  }

  ReportEntity _aggregateReports(List<ReportEntity> reports, DateTime date, {String? agencyId}) {
    if (reports.isEmpty) return _emptyReport(date);

    double totalRevenue = 0;
    int totalDeliveries = 0;
    int openingStock = 0;
    int stockLoaded = 0;
    int totalAvailable = 0;
    int deliveredStock = 0;
    int damagedStock = 0;
    int closingStock = 0;
    int stockMismatch = 0;
    int bottlesDelivered = 0;
    int bottlesReturned = 0;
    int netBottlesOut = 0;
    int totalBottlesWithCustomers = 0;
    double salesRevenue = 0;
    double totalCollected = 0;
    double totalCreditPending = 0;
    double cashSales = 0;
    double onlineSales = 0;
    double securityDepositsCollected = 0;
    double securityDepositsCollectedCash = 0;
    double securityDepositsCollectedOnline = 0;
    double securityDepositsRefunded = 0;
    double securityDepositsRefundedCash = 0;
    double securityDepositsRefundedOnline = 0;
    double netDeposits = 0;
    double totalDepositsHeld = 0;
    double cashInHand = 0;
    double upiCollections = 0;
    
    // Weighted Averages
    double totalAvgPriceWeighted = 0;
    int totalDeliveredForPrice = 0;
    
    int totalCustomers = 0;
    int activeCustomers = 0;
    int newCustomers = 0;
    int inactiveCustomers = 0;
    
    int maxWorkingDays = 0;

    for (var r in reports) {
      final isWarehouse = r.salesmanId == agencyId || r.salesmanId == '';

      totalRevenue += r.totalRevenue;
      
      // Consolidated counts: 
      if (isWarehouse) {
        openingStock = r.openingStock;
        closingStock = r.closingStock;
        damagedStock = r.damagedStock;
        stockMismatch = r.stockMismatch;
      }
      
      if (isWarehouse) {
        // Warehouse specific: Only external refills go here
        stockLoaded += r.stockLoaded;
        // Internal distributions (warehouse -> salesman) ARE the deliveries for the warehouse report
        deliveredStock = r.deliveredStock; 
      } else {
        // Salesman specific: Only customer deliveries go here for the summary card
        totalDeliveries += r.totalDeliveries;
        // Salesman's deliveredStock (customer sales) is NOT added to the warehouse's own deliveredStock total
      }

      bottlesDelivered += r.bottlesDelivered;
      bottlesReturned += r.bottlesReturned;
      netBottlesOut += r.netBottlesOut;
      totalBottlesWithCustomers += r.totalBottlesWithCustomers;

      salesRevenue += r.salesRevenue;
      totalCollected += r.totalCollected;
      totalCreditPending += r.totalCreditPending;
      cashSales += r.cashSales;
      onlineSales += r.onlineSales;
      securityDepositsCollected += r.securityDepositsCollected;
      securityDepositsCollectedCash += r.securityDepositsCollectedCash;
      securityDepositsCollectedOnline += r.securityDepositsCollectedOnline;
      securityDepositsRefunded += r.securityDepositsRefunded;
      securityDepositsRefundedCash += r.securityDepositsRefundedCash;
      securityDepositsRefundedOnline += r.securityDepositsRefundedOnline;
      netDeposits += r.netDeposits;
      totalDepositsHeld += r.totalDepositsHeld;
      cashInHand += r.cashInHand;
      upiCollections += r.upiCollections;
      
      totalDeliveredForPrice += r.totalDeliveries;
      totalAvgPriceWeighted += (r.avgPricePerCan * r.totalDeliveries);
      
      totalCustomers += r.totalCustomers;
      activeCustomers += r.activeCustomers;
      newCustomers += r.newCustomers;
      inactiveCustomers += r.inactiveCustomers;
      
      if (r.workingDays > maxWorkingDays) maxWorkingDays = r.workingDays;
    }

    final agencyTotalAvailable = openingStock + stockLoaded;
    totalAvailable = agencyTotalAvailable;

    final avgPrice = totalDeliveredForPrice > 0 ? totalAvgPriceWeighted / totalDeliveredForPrice : 0.0;
    
    // Correct Agency Level Turnover
    final avgTurnover = agencyTotalAvailable > 0 ? (deliveredStock / agencyTotalAvailable) * 100 : 0.0;
    
    // For agency daily averages, we can divide Total Agency Stats by Max Working Days (or current working days).
    // Or we can sum up average daily revenues? No, sum of averages != average of sums usually, but for daily revenue it is.
    // Let's stick to Total / WorkingDays logic.
    final workingDays = maxWorkingDays; // Or calculation based on date range?
    
    // If it's a daily report, working days is 1 (if active).
    final isDaily = date.month == DateTime.now().month && date.day == DateTime.now().day; // Rough check
    // Actually `maxWorkingDays` from monthly reports will be valid. For daily reports, it will be 0 or 1.
    
    final avgDailyRev = workingDays > 0 ? totalRevenue / workingDays : (isDaily ? totalRevenue : 0.0);
    final avgDailyDel = workingDays > 0 ? totalDeliveries / workingDays : (isDaily ? totalDeliveries.toDouble() : 0.0);

    return ReportEntity(
      date: date,
      totalRevenue: totalRevenue,
      totalDeliveries: totalDeliveries,
      openingStock: openingStock,
      stockLoaded: stockLoaded,
      totalAvailable: totalAvailable,
      deliveredStock: deliveredStock,
      damagedStock: damagedStock,
      closingStock: closingStock,
      stockMismatch: stockMismatch,
      bottlesDelivered: bottlesDelivered,
      bottlesReturned: bottlesReturned,
      netBottlesOut: netBottlesOut,
      totalBottlesWithCustomers: totalBottlesWithCustomers,
      salesRevenue: salesRevenue,
      totalCollected: totalCollected,
      totalCreditPending: totalCreditPending,
      cashSales: cashSales,
      onlineSales: onlineSales,
      securityDepositsCollected: securityDepositsCollected,
      securityDepositsCollectedCash: securityDepositsCollectedCash,
      securityDepositsCollectedOnline: securityDepositsCollectedOnline,
      securityDepositsRefunded: securityDepositsRefunded,
      securityDepositsRefundedCash: securityDepositsRefundedCash,
      securityDepositsRefundedOnline: securityDepositsRefundedOnline,
      netDeposits: netDeposits,
      totalDepositsHeld: totalDepositsHeld,
      cashInHand: cashInHand,
      upiCollections: upiCollections,
      avgPricePerCan: avgPrice,
      stockTurnover: avgTurnover,
      workingDays: workingDays,
      avgDailyRevenue: avgDailyRev,
      avgDailyDeliveries: avgDailyDel,
      totalCustomers: totalCustomers,
      activeCustomers: activeCustomers,
      newCustomers: newCustomers,
      inactiveCustomers: inactiveCustomers,
      subReports: reports.where((r) {
        final isWh = r.salesmanId == agencyId || r.salesmanId == '' || r.salesmanId == null;
        return !isWh;
      }).toList(),
    );
  }


  ReportEntity _emptyReport(DateTime date) {
    return ReportEntity(
      date: date,
      totalRevenue: 0,
      totalDeliveries: 0,
      openingStock: 0,
      stockLoaded: 0,
      totalAvailable: 0,
      deliveredStock: 0,
      damagedStock: 0,
      closingStock: 0,
      stockMismatch: 0,
      bottlesDelivered: 0,
      bottlesReturned: 0,
      netBottlesOut: 0,
      totalBottlesWithCustomers: 0,
      salesRevenue: 0,
      totalCollected: 0,
      totalCreditPending: 0,
      cashSales: 0,
      onlineSales: 0,
      securityDepositsCollected: 0,
      securityDepositsCollectedCash: 0,
      securityDepositsCollectedOnline: 0,
      securityDepositsRefunded: 0,
      securityDepositsRefundedCash: 0,
      securityDepositsRefundedOnline: 0,
      netDeposits: 0,
      totalDepositsHeld: 0,
      cashInHand: 0,
      upiCollections: 0,
      avgPricePerCan: 0,
      stockTurnover: 0,
    );
  }
}
