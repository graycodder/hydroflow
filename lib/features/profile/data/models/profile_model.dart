import 'package:firebase_database/firebase_database.dart';
import 'package:hydroflow/features/profile/domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.role,
    required super.phone,
    required super.email,
    required super.address,
    required super.membershipDate,
    required super.totalSubscriptions,
    required super.totalAmountPaid,
    super.activeCustomers,
    super.currentStock,
    super.customerCount,
    super.isActive,
    required super.joinDate,
    super.lastNotification,
    super.zone,
    super.username,
    super.subId,
    super.subStartDate,
    super.subEndDate,
  });

  factory ProfileModel.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return ProfileModel(
      id: snapshot.key!,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'Salesman Account',
      phone: data['phoneNumber'] as String? ?? data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      membershipDate: data['joinDate'] != null
          ? DateTime.tryParse(data['joinDate'].toString()) ?? DateTime.now()
          : (data['membershipDate'] != null
              ? DateTime.tryParse(data['membershipDate'].toString()) ?? DateTime.now()
              : DateTime.now()),
      totalSubscriptions: (data['totalSubscriptions'] as num?)?.toInt() ?? 0,
      totalAmountPaid: (data['totalAmountPaid'] as num?)?.toDouble() ?? 0.0,
      activeCustomers: (data['activeCustomers'] as num?)?.toInt() ?? 0,
      currentStock: (data['currentStock'] as num?)?.toInt() ?? 0,
      customerCount: (data['customerCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      joinDate: data['joinDate'] != null
          ? DateTime.tryParse(data['joinDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastNotification: data['lastNotification'] != null
          ? DateTime.tryParse(data['lastNotification'].toString())
          : null,
      zone: data['zone'] as String? ?? '',
      username: data['username'] as String? ?? '',
      subId: data['subId'] as String? ?? '',
      subStartDate: data['subStartDate'] != null
          ? DateTime.tryParse(data['subStartDate'].toString())
          : null,
      subEndDate: data['subEndDate'] != null
          ? DateTime.tryParse(data['subEndDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'phone': phone,
      'phoneNumber': phone,
      'email': email,
      'address': address,
      'membershipDate': membershipDate.toIso8601String(),
      'totalSubscriptions': totalSubscriptions,
      'totalAmountPaid': totalAmountPaid,
      'activeCustomers': activeCustomers,
      'currentStock': currentStock,
      'customerCount': customerCount,
      'isActive': isActive,
      'joinDate': joinDate.toIso8601String(),
      'lastNotification': lastNotification?.toIso8601String(),
      'zone': zone,
      'username': username,
      'subId': subId,
      'subStartDate': subStartDate?.toIso8601String(),
      'subEndDate': subEndDate?.toIso8601String(),
    };
  }
}
