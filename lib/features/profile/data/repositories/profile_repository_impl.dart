import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/profile/domain/entities/profile_entity.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:hydroflow/features/profile/domain/repositories/profile_repository.dart';
import 'package:hydroflow/features/profile/data/models/profile_model.dart';
import 'package:hydroflow/features/profile/data/models/subscription_record_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseDatabase _database;

  ProfileRepositoryImpl({required FirebaseDatabase database}) : _database = database;

  @override
  Stream<ProfileEntity> getProfile(String uid) {
    return _database.ref().child('Salesmen').child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        return ProfileModel.fromSnapshot(event.snapshot);
      } else {
        throw Exception('Profile not found');
      }
    });
  }

  @override
  Stream<List<SubscriptionRecord>> getSubscriptionHistory(String uid) {
    return _database.ref().child('Subscription_logs').child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<SubscriptionRecord> history = [];
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          history.add(SubscriptionRecordModel.fromMap(map, key as String));
        });
        
        // Sort by payment date desc
        history.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        return history;
      }
      return [];
    });
  }
}
