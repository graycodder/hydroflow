import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:hydroflow/features/profile/domain/repositories/profile_repository.dart';

class GetSubscriptionHistoryUseCase {
  final ProfileRepository repository;

  GetSubscriptionHistoryUseCase(this.repository);

  Stream<List<SubscriptionRecord>> call(String uid) {
    return repository.getSubscriptionHistory(uid);
  }
}
