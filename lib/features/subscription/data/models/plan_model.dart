import 'package:watermemo/features/subscription/domain/entities/plan.dart';

class PlanModel extends Plan {
  const PlanModel({
    required super.planName,
    required super.price,
    required super.billingCycle,
    required super.maxCustomers,
    required super.maxSalesmen,
    required super.type,
    required super.features,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      planName: map['planName'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      billingCycle: map['billingCycle'] as String? ?? 'Monthly',
      maxCustomers: (map['maxCustomers'] as num?)?.toInt() ?? 0,
      maxSalesmen: (map['maxSalesmen'] as num?)?.toInt() ?? 1,
      type: map['type'] as String? ?? 'individual',
      features: Map<String, bool>.from(map['features'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planName': planName,
      'price': price,
      'billingCycle': billingCycle,
      'maxCustomers': maxCustomers,
      'maxSalesmen': maxSalesmen,
      'type': type,
      'features': features,
    };
  }
}
