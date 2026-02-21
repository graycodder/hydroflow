import 'package:equatable/equatable.dart';

class Salesman extends Equatable {
  final String id;
  final String name;
  final String? agencyName;
  final String agencyId;
  final String role; // 'owner' or 'salesman'
  final String username;
  final String password;
  final int currentStock;
  final bool isActive;
  final DateTime? subscriptionExpiry;
  final double totalDepositsHeld;
  final String? planId;
  final int customerCount;
  final int activeCustomers;
  final int maxCustomers;
  final String address;
  final String phoneNumber;
  final String zone;
  final String? subId;
  final DateTime? subStartDate;
  final DateTime? subEndDate;
  final DateTime? joinDate;
  final DateTime? lastNotification;
  final String? deviceId;
  final int emptyBottles;
  final double pendingCashBalance;
  final DateTime? createdAt;

  const Salesman({
    required this.id,
    required this.name,
    this.agencyName,
    required this.agencyId,
    this.role = 'salesman',
    required this.username,
    required this.password,
    this.currentStock = 0,
    this.isActive = false,
    this.subscriptionExpiry,
    this.totalDepositsHeld = 0.0,
    this.planId,
    this.customerCount = 0,
    this.activeCustomers = 0,
    this.maxCustomers = 0,
    this.address = '',
    this.phoneNumber = '',
    this.zone = '',
    this.subId,
    this.subStartDate,
    this.subEndDate,
    this.joinDate,
    this.lastNotification,
    this.deviceId,
    this.emptyBottles = 0,
    this.pendingCashBalance = 0.0,
    this.createdAt,
  });

  String get displayName =>
      (agencyName != null && agencyName!.isNotEmpty) ? agencyName! : name;

  @override
  List<Object?> get props => [
        id,
        name,
        agencyName,
        agencyId,
        role,
        username,
        password,
        currentStock,
        isActive,
        subscriptionExpiry,
        totalDepositsHeld,
        planId,
        customerCount,
        activeCustomers,
        maxCustomers,
        address,
        phoneNumber,
        zone,
        subId,
        subStartDate,
        subEndDate,
        joinDate,
        lastNotification,
        deviceId,
        emptyBottles,
        pendingCashBalance,
        createdAt,
      ];

  Salesman copyWith({
    String? id,
    String? name,
    String? agencyName,
    String? agencyId,
    String? role,
    String? username,
    String? password,
    int? currentStock,
    bool? isActive,
    DateTime? subscriptionExpiry,
    double? totalDepositsHeld,
    String? planId,
    int? customerCount,
    int? activeCustomers,
    int? maxCustomers,
    String? address,
    String? phoneNumber,
    String? zone,
    String? subId,
    DateTime? subStartDate,
    DateTime? subEndDate,
    DateTime? joinDate,
    DateTime? lastNotification,
    String? deviceId,
    int? emptyBottles,
    double? pendingCashBalance,
    DateTime? createdAt,
  }) {
    return Salesman(
      id: id ?? this.id,
      name: name ?? this.name,
      agencyName: agencyName ?? this.agencyName,
      agencyId: agencyId ?? this.agencyId,
      role: role ?? this.role,
      username: username ?? this.username,
      password: password ?? this.password,
      currentStock: currentStock ?? this.currentStock,
      isActive: isActive ?? this.isActive,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      totalDepositsHeld: totalDepositsHeld ?? this.totalDepositsHeld,
      planId: planId ?? this.planId,
      customerCount: customerCount ?? this.customerCount,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      maxCustomers: maxCustomers ?? this.maxCustomers,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      zone: zone ?? this.zone,
      subId: subId ?? this.subId,
      subStartDate: subStartDate ?? this.subStartDate,
      subEndDate: subEndDate ?? this.subEndDate,
      joinDate: joinDate ?? this.joinDate,
      lastNotification: lastNotification ?? this.lastNotification,
      deviceId: deviceId ?? this.deviceId,
      emptyBottles: emptyBottles ?? this.emptyBottles,
      pendingCashBalance: pendingCashBalance ?? this.pendingCashBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
