import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/profile/data/models/profile_model.dart';
import 'package:hydroflow/features/profile/data/models/subscription_record_model.dart';
import 'package:hydroflow/features/auth/data/models/agency_model.dart';

abstract class ProfileRemoteDataSource {
  Stream<ProfileModel> getProfile(String uid);
  Stream<AgencyModel> getAgencyProfile(String agencyId);
  Stream<List<SubscriptionRecordModel>> getSubscriptionHistory({String? uid, String? agencyId});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseDatabase _database;

  ProfileRemoteDataSourceImpl({required FirebaseDatabase database}) : _database = database;

  @override
  Stream<ProfileModel> getProfile(String uid) {
    return _database.ref().child('Salesmen').child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        return ProfileModel.fromSnapshot(event.snapshot);
      } else {
        throw Exception('Profile not found');
      }
    });
  }

  @override
  Stream<AgencyModel> getAgencyProfile(String agencyId) {
    return _database.ref().child('Agencies').child(agencyId).onValue.map((event) {
      if (event.snapshot.exists) {
        return AgencyModel.fromSnapshot(event.snapshot);
      } else {
        throw Exception('Agency not found');
      }
    });
  }

  @override
  Stream<List<SubscriptionRecordModel>> getSubscriptionHistory({String? uid, String? agencyId}) {
    Query query = _database.ref().child('Subscriptions');

    if (agencyId != null && agencyId.isNotEmpty) {
      query = query.orderByChild('agencyId').equalTo(agencyId);
    } else if (uid != null && uid.isNotEmpty) {
      query = query.orderByChild('salesmanId').equalTo(uid);
    } else {
        return Stream.value([]);
    }

    return query.onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final List<SubscriptionRecordModel> history = [];
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
