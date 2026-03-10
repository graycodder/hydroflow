import 'package:watermemo/features/profile/domain/entities/subscription_record.dart';
import 'package:watermemo/features/profile/domain/repositories/profile_repository.dart';

class GetSubscriptionHistoryUseCase {
  final ProfileRepository repository;

  GetSubscriptionHistoryUseCase(this.repository);

  Stream<List<SubscriptionRecord>> call({String? uid, String? agencyId}) {
    return repository.getSubscriptionHistory(uid: uid, agencyId: agencyId);
  }
}
