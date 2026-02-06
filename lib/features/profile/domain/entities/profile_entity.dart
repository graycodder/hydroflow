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

  // Salesman specific fields
  final int activeCustomers;
  final int currentStock;
  final int customerCount;
  final bool isActive;
  final DateTime joinDate;
  final DateTime? lastNotification;
  final String zone;
  final String username;
  final String subId;
  final DateTime? subStartDate;
  final DateTime? subEndDate;

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
    this.activeCustomers = 0,
    this.currentStock = 0,
    this.customerCount = 0,
    this.isActive = true,
    required this.joinDate,
    this.lastNotification,
    this.zone = '',
    this.username = '',
    this.subId = '',
    this.subStartDate,
    this.subEndDate,
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
        activeCustomers,
        currentStock,
        customerCount,
        isActive,
        joinDate,
        lastNotification,
        zone,
        username,
        subId,
        subStartDate,
        subEndDate,
      ];
}
