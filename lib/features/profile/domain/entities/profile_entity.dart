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

  ProfileEntity copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    String? email,
    String? address,
    DateTime? membershipDate,
    int? totalSubscriptions,
    double? totalAmountPaid,
    int? activeCustomers,
    int? currentStock,
    int? customerCount,
    bool? isActive,
    DateTime? joinDate,
    DateTime? lastNotification,
    String? zone,
    String? username,
    String? subId,
    DateTime? subStartDate,
    DateTime? subEndDate,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      membershipDate: membershipDate ?? this.membershipDate,
      totalSubscriptions: totalSubscriptions ?? this.totalSubscriptions,
      totalAmountPaid: totalAmountPaid ?? this.totalAmountPaid,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      currentStock: currentStock ?? this.currentStock,
      customerCount: customerCount ?? this.customerCount,
      isActive: isActive ?? this.isActive,
      joinDate: joinDate ?? this.joinDate,
      lastNotification: lastNotification ?? this.lastNotification,
      zone: zone ?? this.zone,
      username: username ?? this.username,
      subId: subId ?? this.subId,
      subStartDate: subStartDate ?? this.subStartDate,
      subEndDate: subEndDate ?? this.subEndDate,
    );
  }

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
