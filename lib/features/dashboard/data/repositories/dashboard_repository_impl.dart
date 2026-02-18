import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:hydroflow/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:hydroflow/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:rxdart/rxdart.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseDatabase _database;

  DashboardRepositoryImpl({required FirebaseDatabase database}) : _database = database;

  @override
  Stream<DashboardSummary> getDashboardSummary({required String salesmanId, String? agencyId}) {
    if (agencyId != null && agencyId.isNotEmpty) {
      // --- AGENCY VIEW (OWNER) ---
      // 1. Listen to Agency Stats (aggregated)
      final agencyRef = _database.ref().child('Agencies').child(agencyId).child('stats');
      // 2. Listen to Total Stock in Warehouse
      final stockRef = _database.ref().child('Agencies').child(agencyId).child('stock');
      
      agencyRef.keepSynced(true);
      stockRef.keepSynced(true);

      return Rx.combineLatest2(
        agencyRef.onValue,
        stockRef.onValue,
        (DatabaseEvent statsEvent, DatabaseEvent stockEvent) {
          int currentStock = 0;
          int activeCustomers = 0;
          int inactiveCustomers = 0;
          double todaySales = 0.0;
          double todayCollection = 0.0;
          int todayDeliveries = 0;

          if (stockEvent.snapshot.exists) {
             final stockData = Map<String, dynamic>.from(stockEvent.snapshot.value as Map);
             currentStock = (stockData['fullCans'] as num?)?.toInt() ?? 0;
          }

          if (statsEvent.snapshot.exists) {
            final stats = Map<String, dynamic>.from(statsEvent.snapshot.value as Map);
            activeCustomers = (stats['totalActiveCustomers'] as num?)?.toInt() ?? 0;
            inactiveCustomers = (stats['totalInactiveCustomers'] as num?)?.toInt() ?? 0;
            
            // For now, let's assume stats node has today's aggregates. 
            // In a real app, you might need a separate "Daily_Agency_Stats" node.
            // For simplicity, we will query the SUM of all salesmen logs if not pre-aggregated.
            // But to keep it fast as per request, we should read from a pre-aggregated node.
            // Let's assume we implement a Cloud Function or local logic to update 'Agencies/ID/stats/today...'
            todaySales = (stats['todaySales'] as num?)?.toDouble() ?? 0.0;
            todayCollection = (stats['todayCollection'] as num?)?.toDouble() ?? 0.0;
            todayDeliveries = (stats['todayDeliveries'] as num?)?.toInt() ?? 0;
          }

          return DashboardSummaryModel.fromValues(
            currentStock: currentStock,
            activeCustomers: activeCustomers,
            inactiveCustomers: inactiveCustomers,
            todaySales: todaySales,
            todayCollection: todayCollection,
            todayDeliveries: todayDeliveries,
          );
        }
      );
    } else {
      // --- INDIVIDUAL VIEW (SALESMAN) ---
      final dateKey = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '_');
      
      final salesmanRef = _database.ref().child('Salesmen').child(salesmanId);
      final logRef = _database.ref().child('Stock_logs').child('LOG_${dateKey}_$salesmanId');

      salesmanRef.keepSynced(true);
      logRef.keepSynced(true);

      final salesmanStream = salesmanRef.onValue.map<DataSnapshot?>((e) => e.snapshot).startWith(null);
      final logStream = logRef.onValue.map<DataSnapshot?>((e) => e.snapshot).startWith(null);

      return Rx.combineLatest2<DataSnapshot?, DataSnapshot?, DashboardSummary>(
        salesmanStream,
        logStream,
        (salesmanSnapshot, logSnapshot) {
          int currentStock = 0;
          int activeCount = 0;
          int customerCount = 0;
          
          if (salesmanSnapshot != null && salesmanSnapshot.exists) {
            final data = Map<String, dynamic>.from(salesmanSnapshot.value as Map);
            currentStock = (data['currentStock'] as num?)?.toInt() ?? 0;
            activeCount = (data['activeCustomers'] as num?)?.toInt() ?? 0;
            customerCount = (data['customerCount'] as num?)?.toInt() ?? 0;
          }

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
}
