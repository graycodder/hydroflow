import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

enum CustomerStatus { initial, loading, submitting, success, failure }

class CustomerState extends Equatable {
  final CustomerStatus status;
  final List<Customer> customers;
  final List<Customer> filteredCustomers;
  final String? errorMessage;
  final String? successMessage;
  final int totalCustomers;
  final int activeCustomers;
  final int inactiveCustomers;
  final String? selectedZone;
  final String searchQuery;

  const CustomerState({
    this.status = CustomerStatus.initial,
    this.customers = const [],
    this.filteredCustomers = const [],
    this.errorMessage,
    this.successMessage,
    this.totalCustomers = 0,
    this.activeCustomers = 0,
    this.inactiveCustomers = 0,
    this.selectedZone,
    this.searchQuery = '',
  });

  CustomerState copyWith({
    CustomerStatus? status,
    List<Customer>? customers,
    List<Customer>? filteredCustomers,
    String? errorMessage,
    String? successMessage,
    int? totalCustomers,
    int? activeCustomers,
    int? inactiveCustomers,
    String? selectedZone,
    bool clearSelectedZone = false,
    String? searchQuery,
  }) {
    return CustomerState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      inactiveCustomers: inactiveCustomers ?? this.inactiveCustomers,
      selectedZone: clearSelectedZone ? null : (selectedZone ?? this.selectedZone),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
    status,
    customers,
    filteredCustomers,
    errorMessage,
    successMessage,
    totalCustomers,
    activeCustomers,
    inactiveCustomers,
    selectedZone,
    searchQuery,
  ];
}
