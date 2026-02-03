import 'package:equatable/equatable.dart';

abstract class BottleEvent extends Equatable {
  const BottleEvent();

  @override
  List<Object?> get props => [];
}

class LoadBottleLedger extends BottleEvent {
  final String salesmanId;

  const LoadBottleLedger(this.salesmanId);

  @override
  List<Object?> get props => [salesmanId];
}
