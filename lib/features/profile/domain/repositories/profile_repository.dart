import 'package:hydroflow/features/profile/domain/entities/profile_entity.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';

abstract class ProfileRepository {
  Stream<ProfileEntity> getProfile(String uid);
  Stream<Agency> getAgencyProfile(String agencyId);
  Stream<List<SubscriptionRecord>> getSubscriptionHistory({String? uid, String? agencyId});
}
