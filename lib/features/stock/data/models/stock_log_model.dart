import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';

class StockLogModel extends StockLog {
  const StockLogModel({
    required super.salesmanId,
    required super.date,
    required super.openingStock,
    required super.loaded,
    required super.totalDelivered,
    required super.totalEmptyCollected,
    required super.damaged,
    required super.closingStock,
    super.actualClosingStock = 0,
    super.mismatchCount = 0,
    super.isReconciled = false,
    required super.cashCollected,
    required super.onlineCollected,
  });

  factory StockLogModel.fromMap(Map<String, dynamic> map) {
    return StockLogModel(
      salesmanId: map['salesmanId'] as String? ?? '',
      date: DateTime.tryParse(map['date'].toString()) ?? DateTime.now(),
      openingStock: (map['openingStock'] as num?)?.toInt() ?? 0,
      loaded: (map['loaded'] as num?)?.toInt() ?? 0,
      totalDelivered: (map['totalDelivered'] as num?)?.toInt() ?? 0,
      totalEmptyCollected: (map['totalEmptyCollected'] as num?)?.toInt() ?? 0,
      damaged: (map['damaged'] as num?)?.toInt() ?? 0,
      closingStock: (map['closingStock'] as num?)?.toInt() ?? 0,
      actualClosingStock: (map['actualClosingStock'] as num?)?.toInt() ?? 0,
      mismatchCount: (map['mismatchCount'] as num?)?.toInt() ?? 0,
      isReconciled: map['isReconciled'] as bool? ?? false,
      cashCollected: (map['cashCollected'] as num?)?.toDouble() ?? 0.0,
      onlineCollected: (map['onlineCollected'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salesmanId': salesmanId,
      'date': date.toIso8601String().split('T').first, // YYYY-MM-DD
      'openingStock': openingStock,
      'loaded': loaded,
      'totalDelivered': totalDelivered,
      'totalEmptyCollected': totalEmptyCollected,
      'damaged': damaged,
      'closingStock': closingStock,
      'actualClosingStock': actualClosingStock,
      'mismatchCount': mismatchCount,
      'isReconciled': isReconciled,
      'cashCollected': cashCollected,
      'onlineCollected': onlineCollected,
    };
  }
}
