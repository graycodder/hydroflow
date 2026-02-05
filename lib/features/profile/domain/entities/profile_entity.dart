import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String role;
  final String phone;
  final String email;
  final String address;
  final DateTime membershipDate;
  
  // Subscription related summary fields
  final int totalSubscriptions;
  final double totalAmountPaid;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.email,
    required this.address,
    required this.membershipDate,
    required this.totalSubscriptions,
    required this.totalAmountPaid,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        role,
        phone,
        email,
        address,
        membershipDate,
        totalSubscriptions,
        totalAmountPaid,
      ];
}
