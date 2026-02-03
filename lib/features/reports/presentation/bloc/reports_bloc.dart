import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';
import 'package:hydroflow/features/reports/domain/usecases/get_daily_report_usecase.dart';

// Events
abstract class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object> get props => [];
}

class LoadDailyReport extends ReportsEvent {
  final String salesmanId;
  const LoadDailyReport(this.salesmanId);
  @override
  List<Object> get props => [salesmanId];
}

// State
abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final ReportEntity report;
  const ReportsLoaded(this.report);
  @override
  List<Object?> get props => [report];
}

class ReportsFailure extends ReportsState {
  final String message;
  const ReportsFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetDailyReportUseCase _getDailyReportUseCase;

  ReportsBloc({required GetDailyReportUseCase getDailyReportUseCase})
      : _getDailyReportUseCase = getDailyReportUseCase,
        super(ReportsInitial()) {
    on<LoadDailyReport>(_onLoadDailyReport);
  }

  Future<void> _onLoadDailyReport(
      LoadDailyReport event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    try {
      final report = await _getDailyReportUseCase(event.salesmanId, DateTime.now());
      emit(ReportsLoaded(report));
    } catch (e) {
      emit(ReportsFailure(e.toString()));
    }
  }
}
