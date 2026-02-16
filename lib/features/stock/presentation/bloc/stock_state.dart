import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';

abstract class StockState extends Equatable {
  final StockLog? todayLog;
  final bool hasAnyLogs; 
  
  const StockState({this.todayLog, this.hasAnyLogs = false}); 

  @override
  List<Object?> get props => [todayLog, hasAnyLogs];
}


class StockInitial extends StockState {
  const StockInitial({super.todayLog, super.hasAnyLogs});
}

class StockLoading extends StockState {
  const StockLoading({super.todayLog, super.hasAnyLogs});
}

class StockActionSuccess extends StockState {
  final String message;
  const StockActionSuccess(this.message, {super.todayLog, super.hasAnyLogs});

  @override
  List<Object?> get props => [message, todayLog, hasAnyLogs];
}

class StockFailure extends StockState {
  final String error;
  const StockFailure(this.error, {super.todayLog, super.hasAnyLogs});

  @override
  List<Object?> get props => [error, todayLog, hasAnyLogs];
}

// Added internal data updated state
class StockDataUpdated extends StockState {
  const StockDataUpdated({StockLog? todayLog, bool hasAnyLogs = false}) 
      : super(todayLog: todayLog, hasAnyLogs: hasAnyLogs);
}

