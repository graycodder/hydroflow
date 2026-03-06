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

  const LoadBottleLedger(this.salesmanId);

  @override
  List<Object?> get props => [salesmanId];
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
