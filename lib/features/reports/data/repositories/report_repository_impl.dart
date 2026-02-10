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

    return Rx.combineLatest4<List<TransactionEntity>, List<Customer>, DatabaseEvent, DatabaseEvent, ReportEntity>(
      transactionsStream,
      customersStream,
      logStream,
      salesmanStream,
      (transactions, customers, logEvent, salesmanEvent) {
        // 1. Calculate Bottle Balance from Customers
        final totalBottlesWithCustomers = customers.fold(0, (sum, c) => sum + c.bottleBalance);

        // 2. Parse Stock Logs
        int openingStock = 0;
        int loaded = 0;
        int damaged = 0;
        int stockMismatch = 0;
        
        if (logEvent.snapshot.exists) {
          final data = Map<String, dynamic>.from(logEvent.snapshot.value as Map);
          openingStock = (data['openingStock'] as num?)?.toInt() ?? 0;
          loaded = (data['loaded'] as num?)?.toInt() ?? 0;
          damaged = (data['damaged'] as num?)?.toInt() ?? 0;
          stockMismatch = (data['mismatchCount'] as num?)?.toInt() ?? 0;
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
        int delivered = 0;
        int returned = 0;
        
        for (var tx in transactions) {
          if (tx.type == 'Deposit') {
            securityDepositsCollected += tx.amountReceived;
            totalCollected += tx.amountReceived;
            if (tx.paymentMode == 'Cash') {
              cashFromDeposits += tx.amountReceived;
            } else if (tx.paymentMode == 'Online' || tx.paymentMode == 'UPI') {
              onlineFromDeposits += tx.amountReceived;
            }
            continue; 
          } else if (tx.type == 'Refund') {
             securityDepositsRefunded += tx.amountReceived;
             totalCollected -= tx.amountReceived;
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
        final finalOpening = logEvent.snapshot.exists ? openingStock : (currentStock - loaded + delivered + damaged);
        final finalAvailable = finalOpening + loaded;
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
          closingStock: currentStock,
          stockMismatch: stockMismatch,
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
          securityDepositsRefunded: securityDepositsRefunded,
          netDeposits: netDeposits,
          totalDepositsHeld: totalDepositsHeld,
          cashInHand: cashInHand,
          upiCollections: upiCollections,
          avgPricePerCan: avgPrice,
          stockTurnover: turnover,
          totalCustomers: customers.length,
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
        // 1. Bottle Balance from Customers
        final totalBottlesWithCustomers = customers.fold(0, (sum, c) => sum + c.bottleBalance);

        // 2. Aggregate Stock Logs for the month
        int totalLoaded = 0;
        int totalDamaged = 0;
        int totalMismatch = 0;
        final monthPrefix = month.toIso8601String().substring(0, 7).replaceAll('-', '_');

        if (logsEvent.snapshot.exists) {
          final data = Map<dynamic, dynamic>.from(logsEvent.snapshot.value as Map);
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
        int delivered = 0;
        int returned = 0;

        for (var tx in transactions) {
          if (tx.type == 'Deposit') {
            securityDepositsCollected += tx.amountReceived;
            totalCollected += tx.amountReceived;
            if (tx.paymentMode == 'Cash') {
              cashFromDeposits += tx.amountReceived;
            } else if (tx.paymentMode == 'Online' || tx.paymentMode == 'UPI') {
              onlineFromDeposits += tx.amountReceived;
            }
            continue;
          } else if (tx.type == 'Refund') {
            securityDepositsRefunded += tx.amountReceived;
            totalCollected -= tx.amountReceived;
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

        final calculatedOpening = currentStock + delivered + totalDamaged - totalLoaded;
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
          closingStock: currentStock,
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
          securityDepositsRefunded: securityDepositsRefunded,
          netDeposits: netDeposits,
          totalDepositsHeld: totalDepositsHeld,
          cashInHand: cashInHand,
          upiCollections: upiCollections,
          avgPricePerCan: avgPrice,
          stockTurnover: turnover,
          workingDays: workingDaysCount,
          avgDailyRevenue: avgDailyRev,
          avgDailyDeliveries: avgDailyDel,
          totalCustomers: customers.length,
          activeCustomers: activeCustomerIds.length,
          inactiveCustomers: customers.length - activeCustomerIds.length,
          newCustomers: 0, 
        );
      },
    );
  }
}
