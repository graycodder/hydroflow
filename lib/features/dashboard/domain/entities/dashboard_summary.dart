import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  final int currentStock;
  final int activeCustomers;
  final int inactiveCustomers;
  final int totalCustomers;
  final int newCustomers;
  final double todaySales;
  final double todayCollection;
  final int todayDeliveries;
  final double pendingAmounts;

  const DashboardSummary({
    required this.currentStock,
    required this.activeCustomers,
    required this.inactiveCustomers,
    required this.totalCustomers,
    required this.newCustomers,
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
        totalCustomers,
        newCustomers,
        todaySales,
        todayCollection,
        todayDeliveries,
        pendingAmounts,
      ];
}
