import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.salesmanId,
    required super.customerId,
    required super.timestamp,
    required super.type,
    required super.amount,
    super.amountReceived = 0,
    required super.paymentMode,
    super.cansDelivered = 0,
    super.emptyCollected = 0,
    super.whatsappReceiptSent = false,
    super.notes = '',
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      salesmanId: map['salesmanId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now(),
      type: map['type'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      amountReceived: (map['amountReceived'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] as String? ?? '',
      cansDelivered: (map['cansDelivered'] as num?)?.toInt() ?? 0,
      emptyCollected: (map['emptyCollected'] as num?)?.toInt() ?? 0,
      whatsappReceiptSent: map['whatsappReceiptSent'] as bool? ?? false,
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'salesmanId': salesmanId,
      'customerId': customerId,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'amount': amount,
      'amountReceived': amountReceived,
      'paymentMode': paymentMode,
      'cansDelivered': cansDelivered,
      'emptyCollected': emptyCollected,
      'whatsappReceiptSent': whatsappReceiptSent,
      'notes': notes,
    };
  }
}
