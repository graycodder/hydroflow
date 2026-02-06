import 'package:hydroflow/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:hydroflow/features/profile/domain/entities/profile_entity.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:hydroflow/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  @override
  Stream<ProfileEntity> getProfile(String uid) {
    return _remoteDataSource.getProfile(uid);
  }

  @override
  Stream<List<SubscriptionRecord>> getSubscriptionHistory(String uid) {
    return _remoteDataSource.getSubscriptionHistory(uid);
  }
}
