import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeliveryPage extends DeliveryEvent {
  final String salesmanId;

  const LoadDeliveryPage(this.salesmanId);

  @override
  List<Object?> get props => [salesmanId];
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

class DeliveryDataUpdated extends DeliveryEvent {
  final List<Customer>? customers;
  final List<TransactionEntity>? transactions;

  const DeliveryDataUpdated({this.customers, this.transactions});

  @override
  List<Object?> get props => [customers, transactions];
}
