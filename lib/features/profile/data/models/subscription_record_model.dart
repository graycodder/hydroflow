import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';

class SubscriptionRecordModel extends SubscriptionRecord {
  const SubscriptionRecordModel({
    required super.id,
    required super.planName,
    required super.transactionId,
    required super.paymentDate,
    required super.amount,
    required super.startDate,
    required super.expiryDate,
    required super.duration,
    required super.isAutoRenew,
    required super.paymentMethod,
    required super.salesmanId,
    required super.salesmanName,
    required super.salesmanPhone,
    required super.status,
    required super.isActive,
  });

  factory SubscriptionRecordModel.fromMap(Map<String, dynamic> map, String id) {
    final status = map['status'] as String? ?? 'inactive';
    final startDate = map['startDate'] != null
        ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now()
        : DateTime.now();

    return SubscriptionRecordModel(
      id: id,
      planName: map['planName'] as String? ?? '',
      transactionId: map['transactionId'] as String? ?? '',
      paymentDate: map['paymentDate'] != null
          ? DateTime.tryParse(map['paymentDate'].toString()) ?? startDate
          : startDate,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: startDate,
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'].toString()) ?? DateTime.now()
          : (map['endDate'] != null 
              ? DateTime.tryParse(map['endDate'].toString()) ?? DateTime.now()
              : DateTime.now()),
      duration: map['duration'] as String? ?? '',
      isAutoRenew: map['isAutoRenew'] as bool? ?? false,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      salesmanId: map['salesmanId'] as String? ?? '',
      salesmanName: map['salesmanName'] as String? ?? '',
      salesmanPhone: map['salesmanPhone'] as String? ?? '',
      status: status,
      isActive: status == 'active' || (map['isActive'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planName': planName,
      'transactionId': transactionId,
      'paymentDate': paymentDate.toIso8601String(),
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'duration': duration,
      'isAutoRenew': isAutoRenew,
      'paymentMethod': paymentMethod,
      'salesmanId': salesmanId,
      'salesmanName': salesmanName,
      'salesmanPhone': salesmanPhone,
      'status': status,
      'isActive': isActive,
    };
  }
}
