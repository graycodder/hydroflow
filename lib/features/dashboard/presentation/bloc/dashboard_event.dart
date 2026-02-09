import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/dashboard/domain/entities/dashboard_summary.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {
  final String salesmanId;

  const LoadDashboard(this.salesmanId);

  @override
  List<Object?> get props => [salesmanId];
}

class DashboardUpdated extends DashboardEvent {
  final DashboardSummary summary;

  const DashboardUpdated(this.summary);

  @override
  List<Object?> get props => [summary];
}

class DashboardSummaryError extends DashboardEvent {
  final String message;

  const DashboardSummaryError(this.message);

  @override
  List<Object?> get props => [message];
}
