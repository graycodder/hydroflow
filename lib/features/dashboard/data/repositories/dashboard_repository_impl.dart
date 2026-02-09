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
    final stockStream = _database.ref().child('Salesmen').child(salesmanId).child('currentStock').onValue;
    final customersStream = _database.ref().child('Customers').orderByChild('salesmanId').equalTo(salesmanId).onValue;
    final transactionsStream = _database.ref().child('Transactions').orderByChild('salesmanId').equalTo(salesmanId).onValue;

    return Rx.combineLatest3<DatabaseEvent, DatabaseEvent, DatabaseEvent, DashboardSummary>(
      stockStream,
      customersStream,
      transactionsStream,
      (stockEvent, customersEvent, transactionsEvent) {
        // 1. Parse Stock
        final int currentStock = (stockEvent.snapshot.value as num?)?.toInt() ?? 0;

        // 2. Parse Customers (Active count)
        int activeCount = 0;
        if (customersEvent.snapshot.exists) {
          final data = customersEvent.snapshot.value as Map<dynamic, dynamic>;
          activeCount = data.values.where((v) => (v as Map)['status'] == 'Active').length;
        }

        // 3. Parse Transactions (Today's Sales & Collection)
        double todaySales = 0.0;
        double todayCollection = 0.0;
        int todayDeliveries = 0;
        
        if (transactionsEvent.snapshot.exists) {
          final data = transactionsEvent.snapshot.value as Map<dynamic, dynamic>;
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));

          data.forEach((key, value) {
            final map = Map<String, dynamic>.from(value as Map);
            final timestampStr = map['timestamp'] as String? ?? '';
            final timestamp = DateTime.tryParse(timestampStr) ?? DateTime.now();

            if (timestamp.isAfter(startOfDay) && timestamp.isBefore(endOfDay)) {
              final int cansDelivered = (map['cansDelivered'] as num?)?.toInt() ?? 0;
              final double amount = (map['amount'] as num?)?.toDouble() ?? 0.0;
              final double received = (map['amountReceived'] as num?)?.toDouble() ?? 0.0;

              // Total Sales should be the Bill Amount where actually goods were delivered
              if (cansDelivered > 0) {
                todaySales += amount;
              }
              
              // Total Collection is regardless of goods status (covers debt payments, deposits etc)
              todayCollection += received;
              todayDeliveries += cansDelivered;
            }
          });
        }

        return DashboardSummaryModel.fromValues(
          currentStock: currentStock,
          activeCustomers: activeCount,
          todaySales: todaySales,
          todayCollection: todayCollection,
          todayDeliveries: todayDeliveries,
        );
      },
    );
  }
}
