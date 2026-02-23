import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  final int currentStock;
  final int activeCustomers;
  final int inactiveCustomers;
  final double todaySales;
  final double todayCollection;
  final int todayDeliveries;
  final double pendingAmounts;

  const DashboardSummary({
    required this.currentStock,
    required this.activeCustomers,
    required this.inactiveCustomers,
    required this.todaySales,
    required this.todayCollection,
    required this.todayDeliveries,
    required this.pendingAmounts,
  });

  @override
  List<Object?> get props => [
        currentStock,
        activeCustomers,
        inactiveCustomers,
        todaySales,
        todayCollection,
        todayDeliveries,
        pendingAmounts,
      ];
}
