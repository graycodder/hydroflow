import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hydroflow/features/reports/domain/usecases/record_settlement_usecase.dart';
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

abstract class ReportsStreamEvent extends ReportsEvent {
  const ReportsStreamEvent();
}

class LoadDailyReport extends ReportsStreamEvent {
  final String salesmanId;
  final DateTime date;
  const LoadDailyReport(this.salesmanId, this.date);
  @override
  List<Object> get props => [salesmanId, date];
}

class LoadMonthlyReport extends ReportsStreamEvent {
  final String salesmanId;
  final DateTime month;
  const LoadMonthlyReport(this.salesmanId, this.month);
  @override
  List<Object> get props => [salesmanId, month];
}

class LoadAgencyDailyReport extends ReportsStreamEvent {
  final String agencyId;
  final DateTime date;
  const LoadAgencyDailyReport(this.agencyId, this.date);
  @override
  List<Object> get props => [agencyId, date];
}

class LoadAgencyMonthlyReport extends ReportsStreamEvent {
  final String agencyId;
  final DateTime month;
  const LoadAgencyMonthlyReport(this.agencyId, this.month);
  @override
  List<Object> get props => [agencyId, month];
}

class SettleSalesmanDailyCash extends ReportsEvent {
  final String salesmanId;
  final DateTime date;
  final double amount;
  final String recordedBy;
  final bool isFinal;

  const SettleSalesmanDailyCash({
    required this.salesmanId,
    required this.date,
    required this.amount,
    required this.recordedBy,
    required this.isFinal,
  });

  @override
  List<Object> get props => [salesmanId, date, amount, recordedBy, isFinal];
}

// State
abstract class ReportsState extends Equatable {
  final bool isAgencyView;
  const ReportsState({this.isAgencyView = false});
  @override
  List<Object?> get props => [isAgencyView];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial({super.isAgencyView});
}

class ReportsLoading extends ReportsState {
  const ReportsLoading({super.isAgencyView});
}

class ReportsLoaded extends ReportsState {
  final ReportEntity report;
  final bool isMonthly;
  const ReportsLoaded(this.report, {this.isMonthly = false, super.isAgencyView});
  @override
  List<Object?> get props => [report, isMonthly, isAgencyView];
}

class ReportsFailure extends ReportsState {
  final String message;
  const ReportsFailure(this.message, {super.isAgencyView});
  @override
  List<Object?> get props => [message, isAgencyView];
}

// Bloc
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final GetDailyReportUseCase _getDailyReportUseCase;
  final GetMonthlyReportUseCase _getMonthlyReportUseCase;
  final GetAgencyDailyReportUseCase _getAgencyDailyReportUseCase;
  final GetAgencyMonthlyReportUseCase _getAgencyMonthlyReportUseCase;
  final RecordSettlementUseCase _recordSettlementUseCase;

  ReportsBloc({
    required GetDailyReportUseCase getDailyReportUseCase,
    required GetMonthlyReportUseCase getMonthlyReportUseCase,
    required GetAgencyDailyReportUseCase getAgencyDailyReportUseCase,
    required GetAgencyMonthlyReportUseCase getAgencyMonthlyReportUseCase,
    required RecordSettlementUseCase recordSettlementUseCase,
  })  : _getDailyReportUseCase = getDailyReportUseCase,
        _getMonthlyReportUseCase = getMonthlyReportUseCase,
        _getAgencyDailyReportUseCase = getAgencyDailyReportUseCase,
        _getAgencyMonthlyReportUseCase = getAgencyMonthlyReportUseCase,
        _recordSettlementUseCase = recordSettlementUseCase,
        super(const ReportsInitial()) {
    on<ReportsStreamEvent>(
      (event, emit) async {
        if (event is LoadDailyReport) {
          await _onLoadDailyReport(event, emit);
        } else if (event is LoadMonthlyReport) {
          await _onLoadMonthlyReport(event, emit);
        } else if (event is LoadAgencyDailyReport) {
          await _onLoadAgencyDailyReport(event, emit);
        } else if (event is LoadAgencyMonthlyReport) {
          await _onLoadAgencyMonthlyReport(event, emit);
        }
      },
      transformer: (events, mapper) => events.switchMap(mapper),
    );
    on<SettleSalesmanDailyCash>(_onSettleSalesmanDailyCash);
  }

  Future<void> _onLoadDailyReport(
      LoadDailyReport event, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading(isAgencyView: false));
    await emit.forEach<ReportEntity>(
      _getDailyReportUseCase(event.salesmanId, event.date),
      onData: (report) => ReportsLoaded(report, isMonthly: false, isAgencyView: false),
      onError: (e, stackTrace) => ReportsFailure(e.toString(), isAgencyView: false),
    );
  }

  Future<void> _onLoadMonthlyReport(
      LoadMonthlyReport event, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading(isAgencyView: false));
    await emit.forEach<ReportEntity>(
      _getMonthlyReportUseCase(event.salesmanId, event.month),
      onData: (report) => ReportsLoaded(report, isMonthly: true, isAgencyView: false),
      onError: (e, stackTrace) => ReportsFailure(e.toString(), isAgencyView: false),
    );
  }

  Future<void> _onLoadAgencyDailyReport(
      LoadAgencyDailyReport event, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading(isAgencyView: true));
    await emit.forEach<ReportEntity>(
      _getAgencyDailyReportUseCase(event.agencyId, event.date),
      onData: (report) => ReportsLoaded(report, isMonthly: false, isAgencyView: true),
      onError: (e, stackTrace) => ReportsFailure(e.toString(), isAgencyView: true),
    );
  }

  Future<void> _onLoadAgencyMonthlyReport(
      LoadAgencyMonthlyReport event, Emitter<ReportsState> emit) async {
    emit(const ReportsLoading(isAgencyView: true));
    await emit.forEach<ReportEntity>(
      _getAgencyMonthlyReportUseCase(event.agencyId, event.month),
      onData: (report) => ReportsLoaded(report, isMonthly: true, isAgencyView: true),
      onError: (e, stackTrace) => ReportsFailure(e.toString(), isAgencyView: true),
    );
  }

  Future<void> _onSettleSalesmanDailyCash(
      SettleSalesmanDailyCash event, Emitter<ReportsState> emit) async {
    try {
      await _recordSettlementUseCase(
        salesmanId: event.salesmanId,
        date: event.date,
        amount: event.amount,
        recordedBy: event.recordedBy,
        isFinal: event.isFinal,
      );
      // We don't need to manually emit a new loaded state or call load.
      // Since the UI uses `emit.forEach` on the stream and the stream is based on
      // Firebase `onValue` in the repository, when the `Settlements` node is updated,
      // the real-time stream will automatically emit a new `ReportEntity` with `isSettled` = true.
    } catch (e) {
      // In case of error, just fallback or show failure. Since we are in the middle of a loaded stream,
      // changing state to failure clears the UI. Better to just let UI catch exceptions or handle through a side effect.
      // But for basic flow, we can just print it.
      print("Error settling cash: $e");
    }
  }
}
