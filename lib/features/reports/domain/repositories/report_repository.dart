import 'package:hydroflow/features/reports/domain/entities/report_entity.dart';

abstract class ReportRepository {
  Stream<ReportEntity> getDailyReport(String salesmanId, DateTime date);
  Stream<ReportEntity> getMonthlyReport(String salesmanId, DateTime month);
  Stream<ReportEntity> getAgencyDailyReport(String agencyId, DateTime date);
  Stream<ReportEntity> getAgencyMonthlyReport(String agencyId, DateTime month);
  Future<void> recordSalesmanSettlement(String salesmanId, DateTime date, double amount, String recordedBy);
}
