import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

class SalesmanModel extends Salesman {
  const SalesmanModel({
    required super.id,
    required super.name,
    required super.username,
    required super.password,
    super.currentStock = 0,
    super.isActive = false,
    super.subscriptionExpiry,
    super.totalDepositsHeld = 0.0,
    super.planId,
    super.customerCount = 0,
    super.lastNotification,
  });

  factory SalesmanModel.fromSnapshot(DataSnapshot snapshot) {
    // In RTDB, snapshot.value gives the data map directly
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return SalesmanModel(
      id: snapshot.key!, // The key of the node (e.g., S001)
      name: data['name'] as String? ?? '',
      username: data['username'] as String? ?? '',
      password: data['password'] as String? ?? '',
      currentStock: (data['currentStock'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      subscriptionExpiry: data['subscriptionExpiry'] != null 
          ? DateTime.tryParse(data['subscriptionExpiry'].toString())
          : null,
      totalDepositsHeld: (data['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0,
      planId: data['planId'] as String?,
      customerCount: (data['customerCount'] as num?)?.toInt() ?? 0,
      lastNotification: data['lastNotification'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'password': password,
      'currentStock': currentStock,
      'isActive': isActive,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'totalDepositsHeld': totalDepositsHeld,
      'planId': planId,
      'customerCount': customerCount,
      'lastNotification': lastNotification,
    };
  }
}
