import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardSummaryUseCase _getDashboardSummary;
  StreamSubscription? _dashboardSubscription;

  DashboardBloc({
    required GetDashboardSummaryUseCase getDashboardSummary,
  })  : _getDashboardSummary = getDashboardSummary,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<DashboardUpdated>(_onDashboardUpdated);
    on<DashboardSummaryError>(_onDashboardError);
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    await _dashboardSubscription?.cancel();
    _dashboardSubscription = _getDashboardSummary(
      salesmanId: event.salesmanId,
      agencyId: event.agencyId,
    ).listen(
      (summary) {
        if (!isClosed) {
          add(DashboardUpdated(summary));
        }
      },
      onError: (e) {
        if (!isClosed) {
          add(DashboardSummaryError(e.toString()));
        }
      },
    );
  }

  void _onDashboardUpdated(DashboardUpdated event, Emitter<DashboardState> emit) {
    emit(DashboardLoaded(event.summary));
  }

  void _onDashboardError(DashboardSummaryError event, Emitter<DashboardState> emit) {
    emit(DashboardError(event.message));
  }

  @override
  Future<void> close() {
    _dashboardSubscription?.cancel();
    return super.close();
  }
}
