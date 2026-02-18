import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/domain/entities/agency.dart';

abstract class AgencyState extends Equatable {
  const AgencyState();
  
  @override
  List<Object?> get props => [];
}

class AgencyInitial extends AgencyState {}

class AgencyLoading extends AgencyState {}

class AgencySalesmenLoaded extends AgencyState {
  final List<Salesman> salesmen;
  final Agency? agency;
  final String? message; // Optional message for success actions

  const AgencySalesmenLoaded({required this.salesmen, this.agency, this.message});

  @override
  List<Object?> get props => [salesmen, agency, message];
}

class AgencyActionSuccess extends AgencyState {
  final String message;
  // Included to keep the list visible if needed, or we rely on re-fetching/Bloc state preservation
  // But typically successful actions just show a message.
  
  const AgencyActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AgencyFailure extends AgencyState {
  final String message;

  const AgencyFailure(this.message);

  @override
  List<Object?> get props => [message];
}
