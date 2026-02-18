import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';

abstract class StockState extends Equatable {
  final StockLog? todayLog;
  final bool hasAnyLogs; 
  final Map<String, int>? agencyStock;
  
  const StockState({this.todayLog, this.hasAnyLogs = false, this.agencyStock}); 

  @override
  List<Object?> get props => [todayLog, hasAnyLogs, agencyStock];
}


class StockInitial extends StockState {
  const StockInitial({super.todayLog, super.hasAnyLogs, super.agencyStock});
}

class StockLoading extends StockState {
  const StockLoading({super.todayLog, super.hasAnyLogs, super.agencyStock});
}

class StockActionSuccess extends StockState {
  final String message;
  const StockActionSuccess(this.message, {super.todayLog, super.hasAnyLogs, super.agencyStock});

  @override
  List<Object?> get props => [message, todayLog, hasAnyLogs, agencyStock];
}

class StockFailure extends StockState {
  final String error;
  const StockFailure(this.error, {super.todayLog, super.hasAnyLogs, super.agencyStock});

  @override
  List<Object?> get props => [error, todayLog, hasAnyLogs, agencyStock];
}

// Added internal data updated state
class StockDataUpdated extends StockState {
  const StockDataUpdated({super.todayLog, super.hasAnyLogs = false, super.agencyStock});
}

class StockActionLoading extends StockState {
  const StockActionLoading({super.todayLog, super.hasAnyLogs, super.agencyStock});
}


