import 'package:firebase_database/firebase_database.dart';
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
  Future<ReportEntity> getDailyReport(String salesmanId, DateTime date) async {
    try {
      // 1. Fetch Transactions
      final transactions = await _transactionRepository.getTransactionsByDate(salesmanId, date).first;

      // 2. Fetch Customers (for bottle balance)
      final customers = await _customerRepository.getCustomers(salesmanId).first;
      final totalBottlesWithCustomers = customers.fold(0, (sum, c) => sum + c.bottleBalance);

      // 3. Fetch Stock Logs (Opening/Loaded/Damaged/Mismatch)
      final dateKey = date.toIso8601String().substring(0, 10).replaceAll('-', '_');
      final logSnapshot = await _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId').get();
      
      int openingStock = 0;
      int loaded = 0;
      int damaged = 0;
      int stockMismatch = 0;
      int logClosingStock = 0;
      
      if (logSnapshot.exists) {
        final data = Map<String, dynamic>.from(logSnapshot.value as Map);
        openingStock = (data['openingStock'] as num?)?.toInt() ?? 0;
        loaded = (data['loaded'] as num?)?.toInt() ?? 0;
        damaged = (data['damaged'] as num?)?.toInt() ?? 0;
        stockMismatch = (data['mismatchCount'] as num?)?.toInt() ?? 0;
        logClosingStock = (data['closingStock'] as num?)?.toInt() ?? 0;
      }

      // 4. Fetch Current Stock (Salesman)
      final salesmanSnapshot = await _database.ref().child('Salesmen').child(salesmanId).get();
      // Ensure we cast correctly
      final salesmanData = Map<String, dynamic>.from(salesmanSnapshot.value as Map);
      final currentStock = (salesmanData['currentStock'] as num?)?.toInt() ?? 0;
      final totalDepositsHeld = (salesmanData['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0;

      // 5. Calculate Metrics
      
      // Transaction Aggregates
      double salesRevenue = 0; // Bill Value
      double totalCollected = 0; // Total money received (Sales + Deposits)
      double totalCreditPending = 0; // Bill - Received
      
      double cashSales = 0; // Cash from Goods
      double onlineSales = 0; // Online from Goods

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
           continue; 
        }

        salesRevenue += tx.amount;
        totalCollected += tx.amountReceived;
        totalCreditPending += (tx.amount - tx.amountReceived);
        
        if (tx.paymentMode == 'Cash') {
          cashSales += tx.amountReceived; 
        } else if (tx.paymentMode == 'Online' || tx.paymentMode == 'UPI') {
          onlineSales += tx.amountReceived;
        }
        
        delivered += tx.cansDelivered;
        returned += tx.emptyCollected;
      }
      
      // Stock Reconciliation
      final totalAvailable = openingStock + loaded;
      final closingStock = currentStock; 
      
      // If log exists, use its opening, else fallback to calculation
      final finalOpening = logSnapshot.exists ? openingStock : (currentStock - loaded + delivered + damaged);
      final finalAvailable = finalOpening + loaded;

      // Financials
      final netDeposits = securityDepositsCollected - securityDepositsRefunded;
      
      // Cash In Hand = (Cash from Sales) + (Cash from Deposits) - (Security Deposit Refunds)
      final cashInHand = cashSales + cashFromDeposits - securityDepositsRefunded;
      
      // Online Collections = (Online from Sales) + (Online from Deposits)
      final upiCollections = onlineSales + onlineFromDeposits;
      
      final avgPrice = delivered > 0 ? salesRevenue / delivered : 0.0;
      final turnover = finalAvailable > 0 ? (delivered / finalAvailable) * 100 : 0.0;

      return ReportEntity(
        date: date,
        totalRevenue: salesRevenue, // Strictly goods revenue as per request
        totalDeliveries: delivered,
        openingStock: finalOpening,
        stockLoaded: loaded,
        totalAvailable: finalAvailable,
        deliveredStock: delivered,
        damagedStock: damaged,
        closingStock: closingStock,
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

    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  @override
  Future<ReportEntity> getMonthlyReport(String salesmanId, DateTime month) async {
    try {
      // 1. Fetch Transactions for the month
      final transactions = await _transactionRepository.getTransactionsByMonth(salesmanId, month).first;

      // 2. Fetch Customers (for bottle balance)
      final customers = await _customerRepository.getCustomers(salesmanId).first;
      final totalBottlesWithCustomers = customers.fold(0, (sum, c) => sum + c.bottleBalance);

      // 3. Fetch Stock Logs for the month
      // We'll query all logs for this salesman and filter by month
      final logsSnapshot = await _database.ref()
          .child('Stock_logs')
          .orderByChild('salesmanId')
          .equalTo(salesmanId)
          .get();
      
      int totalLoaded = 0;
      int totalDamaged = 0;
      int totalMismatch = 0;
      
      final monthPrefix = month.toIso8601String().substring(0, 7).replaceAll('-', '_'); // YYYY_MM

      if (logsSnapshot.exists) {
        final data = Map<dynamic, dynamic>.from(logsSnapshot.value as Map);
        data.forEach((key, value) {
          if (key.toString().contains(monthPrefix)) {
            final log = Map<String, dynamic>.from(value as Map);
            totalLoaded += (log['loaded'] as num?)?.toInt() ?? 0;
            totalDamaged += (log['damaged'] as num?)?.toInt() ?? 0;
            totalMismatch += (log['mismatchCount'] as num?)?.toInt() ?? 0;
          }
        });
      }

      // 4. Fetch Current Salesman Data
      final salesmanSnapshot = await _database.ref().child('Salesmen').child(salesmanId).get();
      final salesmanMap = Map<String, dynamic>.from(salesmanSnapshot.value as Map);
      final currentStock = (salesmanMap['currentStock'] as num?)?.toInt() ?? 0;
      final totalDepositsHeld = (salesmanMap['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0;

      // 5. Aggregate Metrics
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
          continue;
        }

        salesRevenue += tx.amount;
        totalCollected += tx.amountReceived;
        totalCreditPending += (tx.amount - tx.amountReceived);
        
        if (tx.paymentMode == 'Cash') {
          cashSales += tx.amountReceived;
        } else if (tx.paymentMode == 'Online' || tx.paymentMode == 'UPI') {
          onlineSales += tx.amountReceived;
        }
        
        delivered += tx.cansDelivered;
        returned += tx.emptyCollected;
      }

      // Financials
      final netDeposits = securityDepositsCollected - securityDepositsRefunded;
      final cashInHand = cashSales + cashFromDeposits - securityDepositsRefunded;
      final upiCollections = onlineSales + onlineFromDeposits;
      final avgPrice = delivered > 0 ? salesRevenue / delivered : 0.0;

      // Opening Stock for Month = (Current Stock + Total Delivered + Total Damaged - Total Loaded)
      // This is a rough estimation since we don't store "Month Opening" explicitly.
      final calculatedOpening = currentStock + delivered + totalDamaged - totalLoaded;
      final totalAvailable = calculatedOpening + totalLoaded;
      final turnover = totalAvailable > 0 ? (delivered / totalAvailable) * 100 : 0.0;

      // 6. Customer Stats
      final activeCustomerIds = transactions.map((t) => t.customerId).toSet();
      final totalCustomersCount = customers.length;
      final activeCustomersCount = activeCustomerIds.length;
      final inactiveCustomersCount = totalCustomersCount - activeCustomersCount;

      // 7. Working Days & Daily Averages
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
        totalCustomers: totalCustomersCount,
        activeCustomers: activeCustomersCount,
        inactiveCustomers: inactiveCustomersCount,
        newCustomers: 0, // Placeholder
      );
    } catch (e) {
      throw Exception('Failed to generate monthly report: $e');
    }
  }
}
