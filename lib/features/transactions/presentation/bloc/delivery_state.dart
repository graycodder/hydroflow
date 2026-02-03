import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

enum DeliveryStatus { initial, loading, success, failure, submissionSuccess }

class DeliveryState extends Equatable {
  final DeliveryStatus status;
  final List<Customer> customers;
  final List<TransactionEntity> todayTransactions;
  final Customer? selectedCustomer;
  final double totalSales;
  final double totalCash;
  final double totalUpi;
  final int totalDelivered;
  final int totalReturned;
  final String? errorMessage;

  const DeliveryState({
    this.status = DeliveryStatus.initial,
    this.customers = const [],
    this.todayTransactions = const [],
    this.selectedCustomer,
    this.totalSales = 0,
    this.totalCash = 0,
    this.totalUpi = 0,
    this.totalDelivered = 0,
    this.totalReturned = 0,
    this.errorMessage,
  });

  DeliveryState copyWith({
    DeliveryStatus? status,
    List<Customer>? customers,
    List<TransactionEntity>? todayTransactions,
    Customer? selectedCustomer,
    bool clearSelectedCustomer = false,
    double? totalSales,
    double? totalCash,
    double? totalUpi,
    int? totalDelivered,
    int? totalReturned,
    String? errorMessage,
  }) {
    return DeliveryState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      todayTransactions: todayTransactions ?? this.todayTransactions,
      selectedCustomer: clearSelectedCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      totalSales: totalSales ?? this.totalSales,
      totalCash: totalCash ?? this.totalCash,
      totalUpi: totalUpi ?? this.totalUpi,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      totalReturned: totalReturned ?? this.totalReturned,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        customers,
        todayTransactions,
        selectedCustomer,
        totalSales,
        totalCash,
        totalUpi,
        totalDelivered,
        totalReturned,
        errorMessage,
      ];
}
