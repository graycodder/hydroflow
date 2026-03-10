import 'package:watermemo/features/reports/domain/repositories/report_repository.dart';
import 'package:watermemo/features/reports/domain/entities/report_entity.dart';

class GetAgencyDailyReportUseCase {
  final ReportRepository repository;

  GetAgencyDailyReportUseCase(this.repository);

  Stream<ReportEntity> call(String agencyId, DateTime date) {
    return repository.getAgencyDailyReport(agencyId, date);
  }
}
