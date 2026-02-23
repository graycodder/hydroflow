import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:hydroflow/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hydroflow/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:hydroflow/features/reports/domain/repositories/report_repository.dart';
import 'package:rxdart/rxdart.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseDatabase _database;
  final ReportRepository? _reportRepository;

  DashboardRepositoryImpl({
    required FirebaseDatabase database,
    ReportRepository? reportRepository,
  }) : _database = database,
       _reportRepository = reportRepository;

  @override
  Stream<DashboardSummary> getDashboardSummary({required String salesmanId, String? agencyId}) {
    if (agencyId != null && agencyId.isNotEmpty && _reportRepository != null) {
      // --- AGENCY VIEW (OWNER) ---
      // We leverage the existing, highly accurate getAgencyDailyReport to aggregate stats cleanly.
      return _reportRepository!.getAgencyDailyReport(agencyId, DateTime.now()).map((report) {
         // Formula: Cash currently in salesmen's hands (including older balances) - What they settled today 
         double pending = report.cashInHand + report.salesmanPreviousBalance - report.settlementAmountToday;
         if (pending < 0) pending = 0;

         return DashboardSummaryModel.fromValues(
            currentStock: report.closingStock, // Warehouse closing stock
            activeCustomers: report.activeCustomers,
            inactiveCustomers: report.inactiveCustomers,
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
          
          if (salesmanEvent.snapshot.exists) {
            final data = Map<String, dynamic>.from(salesmanEvent.snapshot.value as Map);
            currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
            activeCount = (data['activeCustomers'] as num?)?.toInt() ?? 0;
            customerCount = (data['customerCount'] as num?)?.toInt() ?? 0;
          }

          double todaySales = 0.0;
          double todayCollection = 0.0;
          int todayDeliveries = 0;
          double pendingAmounts = 0.0;

          if (logEvent.snapshot.exists) {
            final data = Map<String, dynamic>.from(logEvent.snapshot.value as Map);
            todaySales = (data['totalSalesValue'] as num?)?.toDouble() ?? 0.0;
            todayCollection = (data['todayCollection'] as num?)?.toDouble() ?? 0.0;
            todayDeliveries = (data['totalDelivered'] as num?)?.toInt() ?? 0;
            pendingAmounts = todaySales - todayCollection;
            if(pendingAmounts < 0) pendingAmounts = 0;
          }

          return DashboardSummaryModel.fromValues(
            currentStock: currentStock,
            activeCustomers: activeCount,
            inactiveCustomers: customerCount - activeCount,
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
