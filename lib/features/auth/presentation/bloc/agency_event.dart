import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

abstract class AgencyEvent extends Equatable {
  const AgencyEvent();

  @override
  List<Object> get props => [];
}

class LoadAgencySalesmen extends AgencyEvent {
  final String agencyId;

  const LoadAgencySalesmen(this.agencyId);

  @override
  List<Object> get props => [agencyId];
}

class ResetDevice extends AgencyEvent {
  final String salesmanId;
  final String agencyId;

  const ResetDevice({required this.salesmanId, required this.agencyId});

  @override
  List<Object> get props => [salesmanId, agencyId];
}
class AddSalesman extends AgencyEvent {
  final Salesman salesman;

  const AddSalesman(this.salesman);

  @override
  List<Object> get props => [salesman];
}

class UpdateSalesman extends AgencyEvent {
  final Salesman salesman;

  const UpdateSalesman(this.salesman);

  @override
  List<Object> get props => [salesman];
}
