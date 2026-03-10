import 'package:equatable/equatable.dart';
import 'package:watermemo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';

abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

abstract class DeliveryStreamEvent extends DeliveryEvent {
  const DeliveryStreamEvent();
}

class LoadDeliveryPage extends DeliveryStreamEvent {
  final String salesmanId;
  final bool resetFilters;

  const LoadDeliveryPage(this.salesmanId, {this.resetFilters = false});

  @override
  List<Object?> get props => [salesmanId, resetFilters];
}

class SelectCustomer extends DeliveryEvent {
  final Customer customer;

  const SelectCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class SubmitTransaction extends DeliveryEvent {
  final TransactionEntity transaction;

  const SubmitTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class FilterDeliveryByZone extends DeliveryEvent {
  final String? zone;

  const FilterDeliveryByZone(this.zone);

  @override
  List<Object?> get props => [zone];
}

class LoadAgencyDeliveries extends DeliveryStreamEvent {
  final String agencyId;
  final bool resetFilters;

  const LoadAgencyDeliveries(this.agencyId, {this.resetFilters = false});

  @override
  List<Object?> get props => [agencyId, resetFilters];
}

class FilterDeliveryBySalesman extends DeliveryEvent {
  final String? salesmanId;

  const FilterDeliveryBySalesman(this.salesmanId);

  @override
  List<Object?> get props => [salesmanId];
}

class ResetDeliveryStatus extends DeliveryEvent {}

class ClearDeliveryFilters extends DeliveryEvent {}
