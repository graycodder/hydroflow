import 'package:equatable/equatable.dart';

class SubscriptionRecord extends Equatable {
  final String id;
  final String planName;
  final String transactionId;
  final DateTime paymentDate;
  final double amount;
  final DateTime startDate;
  final DateTime expiryDate;
  final String duration;
  final bool isAutoRenew;
  final String paymentMethod;
  final String salesmanId;
  final String salesmanName;
  final String salesmanPhone;
  final String status;
  final bool isActive;

  const SubscriptionRecord({
    required this.id,
    required this.planName,
    required this.transactionId,
    required this.paymentDate,
    required this.amount,
    required this.startDate,
    required this.expiryDate,
    required this.duration,
    required this.isAutoRenew,
    required this.paymentMethod,
    required this.salesmanId,
    required this.salesmanName,
    required this.salesmanPhone,
    required this.status,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        planName,
        transactionId,
        paymentDate,
        amount,
        startDate,
        expiryDate,
        duration,
        isAutoRenew,
        paymentMethod,
        salesmanId,
        salesmanName,
        salesmanPhone,
        status,
        isActive,
      ];
}
