import 'package:watermemo/features/reports/domain/repositories/report_repository.dart';
import 'package:watermemo/features/reports/domain/entities/report_entity.dart';

class GetDailyReportUseCase {
  final ReportRepository repository;

  GetDailyReportUseCase(this.repository);

  Stream<ReportEntity> call(String salesmanId, DateTime date) {
    return repository.getDailyReport(salesmanId, date);
  }
}
