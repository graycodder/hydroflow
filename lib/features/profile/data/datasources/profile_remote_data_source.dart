import 'package:firebase_database/firebase_database.dart';
import 'package:watermemo/features/profile/data/models/profile_model.dart';
import 'package:watermemo/features/profile/data/models/subscription_record_model.dart';
import 'package:watermemo/features/auth/data/models/agency_model.dart';

abstract class ProfileRemoteDataSource {
  Stream<ProfileModel> getProfile(String uid);
  Stream<AgencyModel> getAgencyProfile(String agencyId);
  Stream<List<SubscriptionRecordModel>> getSubscriptionHistory(
      {String? uid, String? agencyId});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseDatabase _database;

  ProfileRemoteDataSourceImpl({required FirebaseDatabase database})
      : _database = database;

  @override
  Stream<ProfileModel> getProfile(String uid) {
    // Use one-shot .get() instead of .onValue to avoid platform-channel
    // stream cancellation errors on Flutter Web (MissingPluginException).
    return Stream.fromFuture(
      _database.ref().child('Salesmen').child(uid).get().then((snapshot) {
        if (snapshot.exists) {
          return ProfileModel.fromSnapshot(snapshot);
        }
        throw Exception('Profile not found');
      }),
    );
  }

  @override
  Stream<AgencyModel> getAgencyProfile(String agencyId) {
    return Stream.fromFuture(
      _database
          .ref()
          .child('Agencies')
          .child(agencyId)
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          return AgencyModel.fromSnapshot(snapshot);
        }
        throw Exception('Agency not found');
      }),
    );
  }

  @override
  Stream<List<SubscriptionRecordModel>> getSubscriptionHistory(
      {String? uid, String? agencyId}) {
    if ((agencyId == null || agencyId.isEmpty) &&
        (uid == null || uid.isEmpty)) {
      return Stream.value([]);
    }

    Query query = _database.ref().child('Subscriptions');

    if (agencyId != null && agencyId.isNotEmpty) {
      query = query.orderByChild('agencyId').equalTo(agencyId);
    } else {
      query = query.orderByChild('salesmanId').equalTo(uid);
    }

    return Stream.fromFuture(
      query.get().then((snapshot) {
        if (!snapshot.exists) return <SubscriptionRecordModel>[];

        final data = snapshot.value as Map<dynamic, dynamic>;
        final history = <SubscriptionRecordModel>[];
        data.forEach((key, value) {
          final map = Map<String, dynamic>.from(value as Map);
          history.add(SubscriptionRecordModel.fromMap(map, key as String));
        });

        // Sort by payment date descending
        history.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        return history;
      }),
    );
  }
}
