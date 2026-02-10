import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';

abstract class ReportRepository {
  Stream<ReportEntity> getDailyReport(String salesmanId, DateTime date);
  Stream<ReportEntity> getMonthlyReport(String salesmanId, DateTime month);
}
