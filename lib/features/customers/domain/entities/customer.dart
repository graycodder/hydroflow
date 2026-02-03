import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String salesmanId;
  final String name;
  final String phone;
  final String address;
  final String status;
  final double securityDeposit;
  final double pendingBalance;
  final int bottleBalance;
  final bool isRefunded;

  const Customer({
    required this.id,
    required this.salesmanId,
    required this.name,
    required this.phone,
    required this.address,
    required this.status,
    this.securityDeposit = 0.0,
    this.pendingBalance = 0.0,
    this.bottleBalance = 0,
    this.isRefunded = false,
  });

  @override
  List<Object?> get props => [
    id,
    salesmanId,
    name,
    phone,
    address,
    status,
    securityDeposit,
    pendingBalance,
    bottleBalance,
    isRefunded,
  ];
}
