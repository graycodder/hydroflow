import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  final String planName;
  final double price;
  final String billingCycle;
  final int maxCustomers; // -1 for unlimited
  final Map<String, bool> features;

  const Plan({
    required this.planName,
    required this.price,
    required this.billingCycle,
    required this.maxCustomers,
    required this.features,
  });

  @override
  List<Object?> get props => [
        planName,
        price,
        billingCycle,
        maxCustomers,
        features,
      ];
}
