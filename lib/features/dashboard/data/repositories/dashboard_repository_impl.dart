import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:hydroflow/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hydroflow/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:rxdart/rxdart.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseDatabase _database;

  DashboardRepositoryImpl({required FirebaseDatabase database}) : _database = database;

  @override
  Stream<DashboardSummary> getDashboardSummary(String salesmanId) {
    final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
    
    final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
    final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');

    // Enable synchronization for real-time dashboard data
    salesmanRef.keepSynced(true);
    logRef.keepSynced(true);

    final salesmanStream = salesmanRef.onValue.map<DataSnapshot?>((e) => e.snapshot).startWith(null);
    final logStream = logRef.onValue.map<DataSnapshot?>((e) => e.snapshot).startWith(null);


    return Rx.combineLatest2<DataSnapshot?, DataSnapshot?, DashboardSummary>(
      salesmanStream,
      logStream,
      (salesmanSnapshot, logSnapshot) {
        // 1. Parse Salesman Data (Stock and Customer Counts)
        int currentStock = 0;
        int activeCount = 0;
        int customerCount = 0;
        
        if (salesmanSnapshot != null && salesmanSnapshot.exists) {
          final data = Map<String, dynamic>.from(salesmanSnapshot.value as Map);
          currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
          activeCount = (data['activeCustomers'] as num?)?.toInt() ?? 0;
          customerCount = (data['customerCount'] as num?)?.toInt() ?? 0;
        }

        // 2. Parse Aggregated Log Data (Sales and Collections)
        double todaySales = 0.0;
        double todayCollection = 0.0;
        int todayDeliveries = 0;

        if (logSnapshot != null && logSnapshot.exists) {
          final data = Map<String, dynamic>.from(logSnapshot.value as Map);
          todaySales = (data['totalSalesValue'] as num?)?.toDouble() ?? 0.0;
          todayCollection = (data['todayCollection'] as num?)?.toDouble() ?? 0.0;
          todayDeliveries = (data['totalDelivered'] as num?)?.toInt() ?? 0;
        }


        return DashboardSummaryModel.fromValues(
          currentStock: currentStock,
          activeCustomers: activeCount,
          inactiveCustomers: customerCount - activeCount,
          todaySales: todaySales,
          todayCollection: todayCollection,
          todayDeliveries: todayDeliveries,
        );
      },
    );
  }
}
