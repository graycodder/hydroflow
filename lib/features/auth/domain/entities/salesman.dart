import 'package:equatable/equatable.dart';

class Salesman extends Equatable {
  final String id;
  final String name;
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

  const Salesman({
    required this.id,
    required this.name,
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
  });

  @override
  List<Object?> get props => [
    id,
    name,
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
  ];
}
