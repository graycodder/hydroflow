import 'package:hydroflow/features/reports/domain/repositories/report_repository.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';

class GetAgencyMonthlyReportUseCase {
  final ReportRepository repository;

  GetAgencyMonthlyReportUseCase(this.repository);

  Stream<ReportEntity> call(String agencyId, DateTime month) {
    return repository.getAgencyMonthlyReport(agencyId, month);
  }
}
