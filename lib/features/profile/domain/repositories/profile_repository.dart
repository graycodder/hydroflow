import 'package:hydroflow/features/profile/domain/entities/profile_entity.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';

abstract class ProfileRepository {
  Stream<ProfileEntity> getProfile(String uid);
  Stream<List<SubscriptionRecord>> getSubscriptionHistory(String uid);
}
