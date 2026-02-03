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
  final String? lastNotification;

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
    lastNotification,
  ];
}
