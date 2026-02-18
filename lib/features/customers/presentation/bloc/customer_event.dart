import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final String salesmanId;

  const LoadCustomers(this.salesmanId);

  @override
  List<Object> get props => [salesmanId];
}

class LoadAgencyCustomers extends CustomerEvent {
  final String agencyId;

  const LoadAgencyCustomers(this.agencyId);

  @override
  List<Object> get props => [agencyId];
}

class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);

  @override
  List<Object> get props => [query];
}

class AddCustomer extends CustomerEvent {
  final String agencyId;
  final String salesmanId;
  final String name;
  final String phone;
  final String address;
  final String zone;
  final double securityDeposit;
  final String paymentMode;

  const AddCustomer({
    required this.agencyId,
    required this.salesmanId,
    required this.name,
    required this.phone,
    required this.address,
    required this.zone,
    required this.securityDeposit,
    required this.paymentMode,
  });

  @override
  List<Object> get props => [agencyId, salesmanId, name, phone, address, zone, securityDeposit, paymentMode];
}

class UpdateCustomerStatus extends CustomerEvent {
  final String customerId;
  final String status;
  // We need salesmanId to reload the list after update
  final String salesmanId; 

  const UpdateCustomerStatus(this.customerId, this.status, this.salesmanId);

  @override
  List<Object> get props => [customerId, status, salesmanId];
}

class UpdateCustomer extends CustomerEvent {
  final Customer customer;

  const UpdateCustomer(this.customer);

  @override
  List<Object> get props => [customer];
}

class SettleCustomer extends CustomerEvent {
  final Customer customer;
  const SettleCustomer(this.customer);
  @override
  List<Object> get props => [customer];
}

class FilterByZone extends CustomerEvent {
  final String? zone;

  const FilterByZone(this.zone);

  @override
  List<Object> get props => [zone ?? ''];
}

class FilterBySalesman extends CustomerEvent {
  final String? salesmanId;

  const FilterBySalesman(this.salesmanId);

  @override
  List<Object> get props => [salesmanId ?? ''];
}
