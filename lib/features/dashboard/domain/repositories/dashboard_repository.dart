import 'package:hydroflow/features/dashboard/domain/entities/dashboard_summary.dart';

abstract class DashboardRepository {
  Stream<DashboardSummary> getDashboardSummary({required String salesmanId, String? agencyId});
}
