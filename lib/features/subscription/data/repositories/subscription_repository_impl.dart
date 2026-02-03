import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/subscription/domain/entities/plan.dart';
import 'package:hydroflow/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:hydroflow/features/subscription/data/models/plan_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirebaseDatabase _database;

  SubscriptionRepositoryImpl({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Future<List<Plan>> getPlans() async {
    try {
      final ref = _database.ref().child('Plans');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.values.map((value) {
          final map = Map<String, dynamic>.from(value as Map);
          return PlanModel.fromMap(map);
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch plans: $e');
    }
  }
}
