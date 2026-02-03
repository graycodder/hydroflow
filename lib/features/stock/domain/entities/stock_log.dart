import 'package:equatable/equatable.dart';

class StockLog extends Equatable {
  final String salesmanId;
  final DateTime date;
  final int openingStock;
  final int loaded;
  final int totalDelivered;
  final int totalEmptyCollected;
  final int damaged;
  final int closingStock; // Expected or calculated closing
  final int actualClosingStock; // Physical count
  final int mismatchCount; // actual - expected
  final bool isReconciled;
  final double cashCollected;
  final double onlineCollected;

  const StockLog({
    required this.salesmanId,
    required this.date,
    required this.openingStock,
    required this.loaded,
    required this.totalDelivered,
    required this.totalEmptyCollected,
    required this.damaged,
    required this.closingStock,
    this.actualClosingStock = 0,
    this.mismatchCount = 0,
    this.isReconciled = false,
    required this.cashCollected,
    required this.onlineCollected,
  });

  @override
  List<Object?> get props => [
        salesmanId,
        date,
        openingStock,
        loaded,
        totalDelivered,
        totalEmptyCollected,
        damaged,
        closingStock,
        actualClosingStock,
        mismatchCount,
        isReconciled,
        cashCollected,
        onlineCollected,
      ];
}
