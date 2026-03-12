import 'package:firebase_database/firebase_database.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';

class SalesmanModel extends Salesman {
  const SalesmanModel({
    required super.id,
    required super.name,
    super.agencyName,
    required super.agencyId,
    super.role = 'salesman',
    required super.username,
    required super.password,
    super.currentStock = 0,
    super.isActive = false,
    super.subscriptionExpiry,
    super.totalDepositsHeld = 0.0,
    super.planId,
    super.customerCount = 0,
    super.activeCustomers = 0,
    super.maxCustomers = 0,
    super.address = '',
    super.phoneNumber = '',
    super.zone = '',
    super.subId,
    super.subStartDate,
    super.subEndDate,
    super.joinDate,
    super.lastNotification,
    super.deviceId,
    super.emptyBottles = 0,
    super.pendingCashBalance = 0.0,
    super.createdAt,
  });

  factory SalesmanModel.fromSnapshot(DataSnapshot snapshot) {
    // In RTDB, snapshot.value gives the data map directly
    if (snapshot.value == null) {
      throw Exception('Salesman data is null for key: ${snapshot.key}');
    }
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return SalesmanModel(
      id: snapshot.key!, // The key of the node (e.g., S001)
      name: data['name']?.toString() ?? '',
      agencyName: data['agencyName']?.toString(),
      agencyId: data['agencyId']?.toString() ?? '', // Fallback empty for migration
      role: data['role']?.toString() ?? 'salesman',
      username: data['username']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      currentStock: (data['currentStock'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      subscriptionExpiry: data['subEndDate'] != null
          ? DateTime.tryParse(data['subEndDate'].toString())
          : (data['subscriptionExpiry'] != null
                ? DateTime.tryParse(data['subscriptionExpiry'].toString())
                : null),
      totalDepositsHeld: (data['totalDepositsHeld'] as num?)?.toDouble() ?? 0.0,
      planId: data['planId']?.toString(),
      customerCount: (data['customerCount'] as num?)?.toInt() ?? 0,
      activeCustomers: (data['activeCustomers'] as num?)?.toInt() ?? 0,
      maxCustomers: (data['maxCustomers'] as num?)?.toInt() ?? 0,
      address: data['address']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      zone: data['zone']?.toString() ?? '',
      subId: data['subId']?.toString(),
      subStartDate: data['subStartDate'] != null
          ? DateTime.tryParse(data['subStartDate'].toString())
          : null,
      subEndDate: data['subEndDate'] != null
          ? DateTime.tryParse(data['subEndDate'].toString())
          : null,
      joinDate: data['joinDate'] != null
          ? DateTime.tryParse(data['joinDate'].toString())
          : null,
      lastNotification: data['lastNotification'] != null
          ? DateTime.tryParse(data['lastNotification'].toString())
          : null,
      deviceId: data['deviceId'] as String?,
      emptyBottles: (data['emptyBottles'] as num?)?.toInt() ?? 0,
      pendingCashBalance: (data['pendingCashBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'agencyName': agencyName,
      'agencyId': agencyId,
      'role': role,
      'username': username,
      'password': password,
      'currentStock': currentStock,
      'isActive': isActive,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'totalDepositsHeld': totalDepositsHeld,
      'planId': planId,
      'customerCount': customerCount,
      'activeCustomers': activeCustomers,
      'maxCustomers': maxCustomers,
      'address': address,
      'phoneNumber': phoneNumber,
      'zone': zone,
      'subId': subId,
      'subStartDate': subStartDate?.toIso8601String(),
      'subEndDate': subEndDate?.toIso8601String(),
      'joinDate': joinDate?.toIso8601String(),
      'lastNotification': lastNotification?.toIso8601String(),
      'deviceId': deviceId,
      'emptyBottles': emptyBottles,
      'pendingCashBalance': pendingCashBalance,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
