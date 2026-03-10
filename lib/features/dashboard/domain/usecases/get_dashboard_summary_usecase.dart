import 'package:watermemo/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:watermemo/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardSummaryUseCase {
  final DashboardRepository repository;

  GetDashboardSummaryUseCase(this.repository);

  Stream<DashboardSummary> call({required String salesmanId, String? agencyId}) {
    return repository.getDashboardSummary(salesmanId: salesmanId, agencyId: agencyId);
  }
}
