import 'package:watermemo/features/subscription/domain/entities/plan.dart';
import 'package:watermemo/features/subscription/domain/repositories/subscription_repository.dart';

class GetPlansUseCase {
  final SubscriptionRepository repository;

  GetPlansUseCase(this.repository);

  Stream<List<Plan>> call() {
    return repository.getPlans();
  }
}
