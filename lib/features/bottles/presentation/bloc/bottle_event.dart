import 'package:equatable/equatable.dart';

abstract class BottleEvent extends Equatable {
  const BottleEvent();

  @override
  List<Object?> get props => [];
}

abstract class BottleStreamEvent extends BottleEvent {
  const BottleStreamEvent();
}

class LoadBottleLedger extends BottleStreamEvent {
  final String salesmanId;
  final String? agencyId; // Added for route-based fetching
  final String? zone;     // Added for route-based fetching

  const LoadBottleLedger(this.salesmanId, {this.agencyId, this.zone});

  @override
  List<Object?> get props => [salesmanId, agencyId, zone];
}

class LoadAgencyBottleLedger extends BottleStreamEvent {
  final String agencyId;

  const LoadAgencyBottleLedger(this.agencyId);

  @override
  List<Object?> get props => [agencyId];
}

class LoadSalesmanBottleLedger extends BottleStreamEvent {
  final String salesmanId;
  final DateTime date;

  const LoadSalesmanBottleLedger(this.salesmanId, this.date);

  @override
  List<Object?> get props => [salesmanId, date];
}
