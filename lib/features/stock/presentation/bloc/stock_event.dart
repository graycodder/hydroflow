import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

class StockLoadRequested extends StockEvent {
  final String salesmanId;
  final int quantity;

  const StockLoadRequested({required this.salesmanId, required this.quantity});

  @override
  List<Object?> get props => [salesmanId, quantity];
}

class StockDamagedReported extends StockEvent {
  final String salesmanId;
  final int quantity;

  const StockDamagedReported({required this.salesmanId, required this.quantity});

  @override
  List<Object?> get props => [salesmanId, quantity];
}

class LoadStockPage extends StockEvent {
  final String salesmanId;
  const LoadStockPage(this.salesmanId);

  @override
  List<Object?> get props => [salesmanId];
}

class StockLogUpdated extends StockEvent {
  final StockLog? todayLog;
  const StockLogUpdated(this.todayLog);

  @override
  List<Object?> get props => [todayLog];
}

class StockOpeningStockSet extends StockEvent {
  final String salesmanId;
  final int quantity;

  const StockOpeningStockSet({required this.salesmanId, required this.quantity});

  @override
  List<Object?> get props => [salesmanId, quantity];
}

class StockReconciled extends StockEvent {
  final String salesmanId;
  final int physicalCount;

  const StockReconciled({required this.salesmanId, required this.physicalCount});

  @override
  List<Object?> get props => [salesmanId, physicalCount];
}
