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
  final String paymentMode;
  final DateTime? createdAt;

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
    this.paymentMode = 'Cash',
    this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? salesmanId,
    String? name,
    String? phone,
    String? address,
    String? status,
    double? securityDeposit,
    double? pendingBalance,
    int? bottleBalance,
    bool? isRefunded,
    String? paymentMode,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      salesmanId: salesmanId ?? this.salesmanId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      status: status ?? this.status,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      bottleBalance: bottleBalance ?? this.bottleBalance,
      isRefunded: isRefunded ?? this.isRefunded,
      paymentMode: paymentMode ?? this.paymentMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
    paymentMode,
    createdAt,
  ];
}
