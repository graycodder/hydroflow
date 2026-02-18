import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';
import 'package:hydroflow/features/reports/domain/usecases/get_daily_report_usecase.dart';
import 'package:hydroflow/features/reports/domain/usecases/get_monthly_report_usecase.dart';
import 'package:hydroflow/features/reports/domain/usecases/get_agency_daily_report_usecase.dart';
import 'package:hydroflow/features/reports/domain/usecases/get_agency_monthly_report_usecase.dart';

// Events
abstract class ReportsEvent extends Equatable {
  const ReportsEvent();
  @override
  List<Object> get props => [];
}

class LoadDailyReport extends ReportsEvent {
  final String salesmanId;
  final DateTime date;
  const LoadDailyReport(this.salesmanId, this.date);
  @override
  List<Object> get props => [salesmanId, date];
}

class LoadMonthlyReport extends ReportsEvent {
  final String salesmanId;
  final DateTime month;
  const LoadMonthlyReport(this.salesmanId, this.month);
  @override
  List<Object> get props => [salesmanId, month];
}

class LoadAgencyDailyReport extends ReportsEvent {
  final String agencyId;
  final DateTime date;
  const LoadAgencyDailyReport(this.agencyId, this.date);
  @override
  List<Object> get props => [agencyId, date];
}

class LoadAgencyMonthlyReport extends ReportsEvent {
  final String agencyId;
  final DateTime month;
  const LoadAgencyMonthlyReport(this.agencyId, this.month);
  @override
  List<Object> get props => [agencyId, month];
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
  final bool isMonthly;
  const ReportsLoaded(this.report, {this.isMonthly = false});
  @override
  List<Object?> get props => [report, isMonthly];
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
  final GetMonthlyReportUseCase _getMonthlyReportUseCase;
  final GetAgencyDailyReportUseCase _getAgencyDailyReportUseCase;
  final GetAgencyMonthlyReportUseCase _getAgencyMonthlyReportUseCase;

  ReportsBloc({
    required GetDailyReportUseCase getDailyReportUseCase,
    required GetMonthlyReportUseCase getMonthlyReportUseCase,
    required GetAgencyDailyReportUseCase getAgencyDailyReportUseCase,
    required GetAgencyMonthlyReportUseCase getAgencyMonthlyReportUseCase,
  })  : _getDailyReportUseCase = getDailyReportUseCase,
        _getMonthlyReportUseCase = getMonthlyReportUseCase,
        _getAgencyDailyReportUseCase = getAgencyDailyReportUseCase,
        _getAgencyMonthlyReportUseCase = getAgencyMonthlyReportUseCase,
        super(ReportsInitial()) {
    on<LoadDailyReport>(_onLoadDailyReport);
    on<LoadMonthlyReport>(_onLoadMonthlyReport);
    on<LoadAgencyDailyReport>(_onLoadAgencyDailyReport);
    on<LoadAgencyMonthlyReport>(_onLoadAgencyMonthlyReport);
  }

  Future<void> _onLoadDailyReport(
      LoadDailyReport event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    await emit.forEach<ReportEntity>(
      _getDailyReportUseCase(event.salesmanId, event.date),
      onData: (report) => ReportsLoaded(report, isMonthly: false),
      onError: (e, stackTrace) => ReportsFailure(e.toString()),
    );
  }

  Future<void> _onLoadMonthlyReport(
      LoadMonthlyReport event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    await emit.forEach<ReportEntity>(
      _getMonthlyReportUseCase(event.salesmanId, event.month),
      onData: (report) => ReportsLoaded(report, isMonthly: true),
      onError: (e, stackTrace) => ReportsFailure(e.toString()),
    );
  }

  Future<void> _onLoadAgencyDailyReport(
      LoadAgencyDailyReport event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    await emit.forEach<ReportEntity>(
      _getAgencyDailyReportUseCase(event.agencyId, event.date),
      onData: (report) => ReportsLoaded(report, isMonthly: false),
      onError: (e, stackTrace) => ReportsFailure(e.toString()),
    );
  }

  Future<void> _onLoadAgencyMonthlyReport(
      LoadAgencyMonthlyReport event, Emitter<ReportsState> emit) async {
    emit(ReportsLoading());
    await emit.forEach<ReportEntity>(
      _getAgencyMonthlyReportUseCase(event.agencyId, event.month),
      onData: (report) => ReportsLoaded(report, isMonthly: true),
      onError: (e, stackTrace) => ReportsFailure(e.toString()),
    );
  }
}
