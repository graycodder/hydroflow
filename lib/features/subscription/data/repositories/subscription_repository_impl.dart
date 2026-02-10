import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/subscription/domain/entities/plan.dart';
import 'package:hydroflow/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:hydroflow/features/subscription/data/models/plan_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirebaseDatabase _database;

  SubscriptionRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Stream<List<Plan>> getPlans() {
    final ref = _database.ref().child('Plans');
    return ref.onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return data.values.map((value) {
          final map = Map<String, dynamic>.from(value as Map);
          return PlanModel.fromMap(map);
        }).toList();
      }
      return [];
    });
  }
}
