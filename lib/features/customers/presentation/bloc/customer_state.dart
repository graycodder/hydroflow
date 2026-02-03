import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

enum CustomerStatus { initial, loading, success, failure }

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final String? errorMessage;
  final int totalCustomers;
  final int activeCustomers;
  final int inactiveCustomers;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.filteredCustomers = const [],
    this.errorMessage,
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.inactiveCustomers = 0,
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<Customer>? customers,
    List<Customer>? filteredCustomers,
    String? errorMessage,
    int? totalCustomers,
    int? activeCustomers,
    int? inactiveCustomers,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      errorMessage: errorMessage ?? this.errorMessage,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      inactiveCustomers: inactiveCustomers ?? this.inactiveCustomers,
    );
  }

  @override
  List<Object?> get props => [
    status,
    customers,
    filteredCustomers,
    errorMessage,
    totalCustomers,
    activeCustomers,
    inactiveCustomers,
  ];
}
