import 'package:firebase_database/firebase_database.dart';
import 'package:watermemo/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:watermemo/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:watermemo/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:watermemo/features/reports/domain/repositories/report_repository.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';
import 'package:rxdart/rxdart.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseDatabase _database;
  final ReportRepository? _reportRepository;
  final CustomerRepository? _customerRepository;

  DashboardRepositoryImpl({
    required FirebaseDatabase database,
    ReportRepository? reportRepository,
    CustomerRepository? customerRepository,
  }) : _database = database,
       _reportRepository = reportRepository,
       _customerRepository = customerRepository;

  @override
  Stream<DashboardSummary> getDashboardSummary({required String salesmanId, String? agencyId}) {
    if (agencyId != null && agencyId.isNotEmpty && _reportRepository != null && _customerRepository != null) {
      // --- AGENCY VIEW (OWNER) ---
      // We leverage getAgencyDailyReport for financial/stock stats,
      // and getCustomersByAgency for high-precision, real-time customer counts (matching CustomersPage).
      final reportStream = _reportRepository!.getAgencyDailyReport(agencyId, DateTime.now());
      final customersStream = _customerRepository!.getCustomersByAgency(agencyId);

      return Rx.combineLatest2(reportStream, customersStream, (report, customers) {
         final activeCount = customers.where((c) => c.status == 'Active').length;
         final inactiveCount = customers.length - activeCount;
         
         final now = DateTime.now();
         final newCount = customers.where((c) {
            if (c.createdAt == null) return false;
            return c.createdAt!.year == now.year && c.createdAt!.month == now.month && c.createdAt!.day == now.day;
         }).length;
         
         double pending = report.pendingCashBalance;
         if (pending < 0) pending = 0;

         return DashboardSummaryModel.fromValues(
            currentStock: report.closingStock,
            activeCustomers: activeCount,
            inactiveCustomers: inactiveCount,
            totalCustomers: customers.length,
            newCustomers: newCount,
            todaySales: report.salesRevenue,
            todayCollection: report.totalCollected,
            todayDeliveries: report.totalDeliveries,
            pendingAmounts: pending,
          );
      });
    } else {
      // --- INDIVIDUAL VIEW (SALESMAN) ---
      final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
      
      final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
      final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');

      salesmanRef.keepSynced(true);
      logRef.keepSynced(true);

      return Rx.combineLatest2(
        salesmanRef.onValue,
        logRef.onValue,
        (DatabaseEvent salesmanEvent, DatabaseEvent logEvent) {
          int currentStock = 0;
          int activeCount = 0;
          int customerCount = 0;
          double pendingAmounts = 0.0;
          
          if (salesmanEvent.snapshot.exists) {
            final data = Map<String, dynamic>.from(salesmanEvent.snapshot.value as Map);
            currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
            activeCount = (data['activeCustomers'] as num?)?.toInt() ?? 0;
            customerCount = (data['customerCount'] as num?)?.toInt() ?? 0;
            pendingAmounts = (data['pendingCashBalance'] as num?)?.toDouble() ?? 0.0;
            if (pendingAmounts < 0) pendingAmounts = 0;
          }
          double todaySales = 0.0;
          double todayCollection = 0.0;
          int todayDeliveries = 0;

          if (logEvent.snapshot.exists) {
            final data = Map<String, dynamic>.from(logEvent.snapshot.value as Map);
            todaySales = (data['totalSalesValue'] as num?)?.toDouble() ?? 0.0;
            todayCollection = (data['todayCollection'] as num?)?.toDouble() ?? 0.0;
            todayDeliveries = (data['totalDelivered'] as num?)?.toInt() ?? 0;
          }

          return DashboardSummaryModel.fromValues(
            currentStock: currentStock,
            activeCustomers: activeCount,
            inactiveCustomers: customerCount - activeCount,
            totalCustomers: customerCount,
            newCustomers: 0, // Individual view doesn't track daily new customers directly in salesman node yet, could be added later
            todaySales: todaySales,
            todayCollection: todayCollection,
            todayDeliveries: todayDeliveries,
            pendingAmounts: pendingAmounts,
          );
        },
      );
    }
  }
}
