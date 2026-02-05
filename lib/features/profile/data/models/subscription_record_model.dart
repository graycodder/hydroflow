import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';

class SubscriptionRecordModel extends SubscriptionRecord {
  const SubscriptionRecordModel({
    required super.id,
    required super.planName,
    required super.transactionId,
    required super.paymentDate,
    required super.amount,
    required super.startDate,
    required super.endDate,
    required super.duration,
    required super.isActive,
  });

  factory SubscriptionRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionRecordModel(
      id: id,
      planName: map['planName'] as String? ?? '',
      transactionId: map['transactionId'] as String? ?? '',
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      duration: map['duration'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planName': planName,
      'transactionId': transactionId,
      'paymentDate': paymentDate.toIso8601String(),
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'duration': duration,
      'isActive': isActive,
    };
  }
}
