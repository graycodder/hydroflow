import 'package:hydroflow/features/reports/domain/repositories/report_repository.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';

class GetMonthlyReportUseCase {
  final ReportRepository repository;

  GetMonthlyReportUseCase(this.repository);

  Stream<ReportEntity> call(String salesmanId, DateTime month) {
    return repository.getMonthlyReport(salesmanId, month);
  }
}
