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

class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);

  @override
  List<Object> get props => [query];
}

class AddCustomer extends CustomerEvent {
  final String salesmanId;
  final String name;
  final String phone;
  final String address;
  final double securityDeposit;

  const AddCustomer({
    required this.salesmanId,
    required this.name,
    required this.phone,
    required this.address,
    required this.securityDeposit,
  });

  @override
  List<Object> get props => [salesmanId, name, phone, address, securityDeposit];
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
