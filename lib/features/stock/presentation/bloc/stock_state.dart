import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';

abstract class StockState extends Equatable {
  final StockLog? todayLog;
  const StockState({this.todayLog});

  @override
  List<Object?> get props => [todayLog];
}

class StockInitial extends StockState {
  const StockInitial({super.todayLog});
}

class StockLoading extends StockState {
  const StockLoading({super.todayLog});
}

class StockActionSuccess extends StockState {
  final String message;
  const StockActionSuccess(this.message, {super.todayLog});

  @override
  List<Object?> get props => [message, todayLog];
}

class StockFailure extends StockState {
  final String error;
  const StockFailure(this.error, {super.todayLog});

  @override
  List<Object?> get props => [error, todayLog];
}

// Added internal data updated state
class StockDataUpdated extends StockState {
  const StockDataUpdated(StockLog? todayLog) : super(todayLog: todayLog);
}
