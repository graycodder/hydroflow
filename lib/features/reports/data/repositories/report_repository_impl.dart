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
      // limitation: getTodayTransactions uses 'now'. We might need 'getByDate'.
      // But for 'End of Day Report', assuming 'today' is fine for now.
      final transactions = await _transactionRepository.getTodayTransactions(salesmanId).first;

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
      final salesmanSnapshot = await _database.ref().child('Salesmen').child(salesmanId).child('currentStock').get();
      final currentStock = (salesmanSnapshot.value as num?)?.toInt() ?? 0;

      // 5. Calculate Metrics
      
      // Transaction Aggregates
      double salesRevenue = 0; // Bill Value
      double totalCollected = 0; // Actual Received
      double totalCreditPending = 0; // Bill - Received
      
      double cashSales = 0; // Actual Cash
      double onlineSales = 0; // Actual Online
      
      int delivered = 0;
      int returned = 0;
      
      for (var tx in transactions) {
        salesRevenue += tx.amount;
        totalCollected += tx.amountReceived;
        totalCreditPending += (tx.amount - tx.amountReceived);
        
        if (tx.paymentMode == 'Cash') {
          cashSales += tx.amountReceived; // Use Received amount, not Bill amount
        } else if (tx.paymentMode == 'Online' || tx.paymentMode == 'UPI') {
          onlineSales += tx.amountReceived; // Use Received amount
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
      const double securityDepositsCollected = 0;
      const double securityDepositsRefunded = 0;
      const double netDeposits = 0;
      
      final cashInHand = cashSales + securityDepositsCollected - securityDepositsRefunded;
      final upiCollections = onlineSales;
      
      final avgPrice = delivered > 0 ? salesRevenue / delivered : 0.0;
      final turnover = finalAvailable > 0 ? (delivered / finalAvailable) * 100 : 0.0;

      return ReportEntity(
        date: date,
        totalRevenue: salesRevenue + netDeposits,
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
        cashInHand: cashInHand,
        upiCollections: upiCollections,
        avgPricePerCan: avgPrice,
        stockTurnover: turnover,
      );

    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }
}
