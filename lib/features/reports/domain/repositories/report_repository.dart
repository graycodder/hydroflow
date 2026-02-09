import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';

abstract class ReportRepository {
  Future<ReportEntity> getDailyReport(String salesmanId, DateTime date);
  Future<ReportEntity> getMonthlyReport(String salesmanId, DateTime month);
}
