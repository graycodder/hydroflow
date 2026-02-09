import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  final int currentStock;
  final int activeCustomers;
  final double todaySales;
  final double todayCollection;
  final int todayDeliveries;

  const DashboardSummary({
    required this.currentStock,
    required this.activeCustomers,
    required this.todaySales,
    required this.todayCollection,
    required this.todayDeliveries,
  });

  @override
  List<Object?> get props => [
        currentStock,
        activeCustomers,
        todaySales,
        todayCollection,
        todayDeliveries,
      ];
}
