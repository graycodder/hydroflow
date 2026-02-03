import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String salesmanId;
  final String customerId;
  final DateTime timestamp;
  final String type;
  final double amount;
  final String paymentMode;
  final int cansDelivered;
  final int emptyCollected;
  final bool whatsappReceiptSent;
  final String notes;

  const TransactionEntity({
    required this.id,
    required this.salesmanId,
    required this.customerId,
    required this.timestamp,
    required this.type,
    required this.amount,
    required this.paymentMode,
    this.cansDelivered = 0,
    this.emptyCollected = 0,
    this.whatsappReceiptSent = false,
    this.notes = '',
  });

  @override
  List<Object?> get props => [
    id,
    salesmanId,
    customerId,
    timestamp,
    type,
    amount,
    paymentMode,
    cansDelivered,
    emptyCollected,
    whatsappReceiptSent,
    notes,
  ];
}
