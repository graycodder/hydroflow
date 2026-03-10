import 'package:watermemo/features/subscription/domain/entities/plan.dart';

abstract class SubscriptionRepository {
  Stream<List<Plan>> getPlans();
}
