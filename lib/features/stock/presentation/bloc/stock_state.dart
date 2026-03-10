import 'package:equatable/equatable.dart';
import 'package:watermemo/features/stock/domain/entities/stock_log.dart';

abstract class StockState extends Equatable {
  final StockLog? todayLog;
  final bool hasAnyLogs; 
  final Map<String, int>? agencyStock;
  final bool isAgencyView;
  
  const StockState({
    this.todayLog, 
    this.hasAnyLogs = false, 
    this.agencyStock,
    this.isAgencyView = false,
  }); 

  @override
  List<Object?> get props => [todayLog, hasAnyLogs, agencyStock, isAgencyView];
}


class StockInitial extends StockState {
  const StockInitial({super.todayLog, super.hasAnyLogs, super.agencyStock, super.isAgencyView});
}

class StockLoading extends StockState {
  const StockLoading({super.todayLog, super.hasAnyLogs, super.agencyStock, super.isAgencyView});
}

class StockActionSuccess extends StockState {
  final String message;
  const StockActionSuccess(this.message, {super.todayLog, super.hasAnyLogs, super.agencyStock, super.isAgencyView});

  @override
  List<Object?> get props => [message, todayLog, hasAnyLogs, agencyStock, isAgencyView];
}

class StockFailure extends StockState {
  final String error;
  const StockFailure(this.error, {super.todayLog, super.hasAnyLogs, super.agencyStock, super.isAgencyView});

  @override
  List<Object?> get props => [error, todayLog, hasAnyLogs, agencyStock, isAgencyView];
}

// Added internal data updated state
class StockDataUpdated extends StockState {
  const StockDataUpdated({super.todayLog, super.hasAnyLogs = false, super.agencyStock, super.isAgencyView});
}

class StockActionLoading extends StockState {
  const StockActionLoading({super.todayLog, super.hasAnyLogs, super.agencyStock, super.isAgencyView});
}


