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
  });

  factory ProfileModel.fromSnapshot(DataSnapshot snapshot) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return ProfileModel(
      id: snapshot.key!,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'Salesman Account',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: data['address'] as String? ?? '',
      membershipDate: data['membershipDate'] != null
          ? DateTime.tryParse(data['membershipDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      totalSubscriptions: (data['totalSubscriptions'] as num?)?.toInt() ?? 0,
      totalAmountPaid: (data['totalAmountPaid'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'phone': phone,
      'email': email,
      'address': address,
      'membershipDate': membershipDate.toIso8601String(),
      'totalSubscriptions': totalSubscriptions,
      'totalAmountPaid': totalAmountPaid,
    };
  }
}
