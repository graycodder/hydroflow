import 'package:hydroflow/features/subscription/domain/entities/plan.dart';
import 'package:hydroflow/features/subscription/domain/repositories/subscription_repository.dart';

class GetPlansUseCase {
  final SubscriptionRepository repository;

  GetPlansUseCase(this.repository);

  Future<List<Plan>> call() {
    return repository.getPlans();
  }
}
