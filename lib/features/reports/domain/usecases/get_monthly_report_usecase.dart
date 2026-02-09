import 'package:hydroflow/features/reports/domain/repositories/report_repository.dart';
import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';

class GetMonthlyReportUseCase {
  final ReportRepository repository;

  GetMonthlyReportUseCase(this.repository);

  Future<ReportEntity> call(String salesmanId, DateTime month) async {
    return await repository.getMonthlyReport(salesmanId, month);
  }
}
