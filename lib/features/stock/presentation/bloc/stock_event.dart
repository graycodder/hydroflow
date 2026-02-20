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
  final String? agencyId; // For trading mode

  const StockLoadRequested({required this.salesmanId, required this.quantity, this.agencyId});

  @override
  List<Object?> get props => [salesmanId, quantity, agencyId];
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
  final String? agencyId;

  const StockOpeningStockSet({required this.salesmanId, required this.quantity, this.agencyId});

  @override
  List<Object?> get props => [salesmanId, quantity, agencyId];
}

class StockReconciled extends StockEvent {
  final String salesmanId;
  final int physicalCount;

  const StockReconciled({required this.salesmanId, required this.physicalCount});

  @override
  List<Object?> get props => [salesmanId, physicalCount];
}

class StockAgencyPurchase extends StockEvent {
  final String agencyId;
  final int quantity;

  const StockAgencyPurchase({required this.agencyId, required this.quantity});

  @override
  List<Object?> get props => [agencyId, quantity];
}

class LoadAgencyStock extends StockEvent {
  final String agencyId;
  const LoadAgencyStock(this.agencyId);
  @override
  List<Object?> get props => [agencyId];
}

class AgencyStockUpdated extends StockEvent {
  final Map<String, int> stock;
  const AgencyStockUpdated(this.stock);
  @override
  List<Object?> get props => [stock];
}

class AgencyStockOpeningStockSet extends StockEvent {
  final String agencyId;
  final int quantity;
  const AgencyStockOpeningStockSet({required this.agencyId, required this.quantity});
  @override
  List<Object?> get props => [agencyId, quantity];
}

class AgencyStockRefillRequested extends StockEvent {
  final String agencyId;
  final int quantity;
  const AgencyStockRefillRequested({required this.agencyId, required this.quantity});
  @override
  List<Object?> get props => [agencyId, quantity];
}

class AgencyStockDamagedReported extends StockEvent {
  final String agencyId;
  final int quantity;
  const AgencyStockDamagedReported({required this.agencyId, required this.quantity});
  @override
  List<Object?> get props => [agencyId, quantity];
}
class EmptyBottlesCollected extends StockEvent {
  final String salesmanId;
  final String agencyId;
  final int quantity;

  const EmptyBottlesCollected({
    required this.salesmanId,
    required this.agencyId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [salesmanId, agencyId, quantity];
}
