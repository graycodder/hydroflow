import 'package:equatable/equatable.dart';

class SubscriptionRecord extends Equatable {
  final String id;
  final String planName;
  final String transactionId;
  final DateTime paymentDate;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String duration;
  final bool isActive;

  const SubscriptionRecord({
    required this.id,
    required this.planName,
    required this.transactionId,
    required this.paymentDate,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.duration,
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
        endDate,
        duration,
        isActive,
      ];
}
