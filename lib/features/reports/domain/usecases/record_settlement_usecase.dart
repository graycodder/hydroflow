import 'package:watermemo/features/reports/domain/repositories/report_repository.dart';

class RecordSettlementUseCase {
  final ReportRepository repository;

  RecordSettlementUseCase(this.repository);

  Future<void> call({
    required String salesmanId,
    required DateTime date,
    required double amount,
    required String recordedBy,
    required bool isFinal,
  }) async {
    return await repository.recordSalesmanSettlement(
      salesmanId,
      date,
      amount,
      recordedBy,
      isFinal,
    );
  }
}
