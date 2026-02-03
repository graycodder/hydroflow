import 'package:hydroflow/features/reports/domain/repositories/report_repository.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';

class GetDailyReportUseCase {
  final ReportRepository repository;

  GetDailyReportUseCase(this.repository);

  Future<ReportEntity> call(String salesmanId, DateTime date) async {
    return await repository.getDailyReport(salesmanId, date);
  }
}
