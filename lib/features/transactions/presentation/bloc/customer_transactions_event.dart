import 'package:equatable/equatable.dart';

abstract class CustomerTransactionsEvent extends Equatable {
  const CustomerTransactionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomerTransactions extends CustomerTransactionsEvent {
  final String customerId;

  const LoadCustomerTransactions(this.customerId);

  @override
  List<Object?> get props => [customerId];
}
