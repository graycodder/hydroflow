import 'package:hydroflow/features/dashboard/domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.currentStock,
    required super.activeCustomers,
    required super.inactiveCustomers,
    required super.todaySales,
    required super.todayCollection,
    required super.todayDeliveries,
    required super.pendingAmounts,
  });

  factory DashboardSummaryModel.fromValues({
    required int currentStock,
    required int activeCustomers,
    required int inactiveCustomers,
    required double todaySales,
    required double todayCollection,
    required int todayDeliveries,
    required double pendingAmounts,
  }) {
    return DashboardSummaryModel(
      currentStock: currentStock,
      activeCustomers: activeCustomers,
      inactiveCustomers: inactiveCustomers,
      todaySales: todaySales,
      todayCollection: todayCollection,
      todayDeliveries: todayDeliveries,
      pendingAmounts: pendingAmounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStock': currentStock,
      'activeCustomers': activeCustomers,
      'inactiveCustomers': inactiveCustomers,
      'todaySales': todaySales,
      'todayCollection': todayCollection,
      'todayDeliveries': todayDeliveries,
      'pendingAmounts': pendingAmounts,
    };
  }
}
