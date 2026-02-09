import 'package:hydroflow/features/dashboard/domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.currentStock,
    required super.activeCustomers,
    required super.todaySales,
    required super.todayCollection,
    required super.todayDeliveries,
  });

  factory DashboardSummaryModel.fromValues({
    required int currentStock,
    required int activeCustomers,
    required double todaySales,
    required double todayCollection,
    required int todayDeliveries,
  }) {
    return DashboardSummaryModel(
      currentStock: currentStock,
      activeCustomers: activeCustomers,
      todaySales: todaySales,
      todayCollection: todayCollection,
      todayDeliveries: todayDeliveries,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStock': currentStock,
      'activeCustomers': activeCustomers,
      'todaySales': todaySales,
      'todayCollection': todayCollection,
      'todayDeliveries': todayDeliveries,
    };
  }
}
