import 'package:hydroflow/features/subscription/domain/entities/plan.dart';

abstract class SubscriptionRepository {
  Future<List<Plan>> getPlans();
}
