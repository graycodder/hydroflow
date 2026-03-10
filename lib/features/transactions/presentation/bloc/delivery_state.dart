import 'package:equatable/equatable.dart';
import 'package:watermemo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';

enum DeliveryStatus { initial, loading, submitting, success, failure, submissionSuccess }

class DeliveryState extends Equatable {
  final DeliveryStatus status;
  final List<Customer> customers;
  final List<TransactionEntity> todayTransactions;
  final List<TransactionEntity> allTodayTransactions;
  final Customer? selectedCustomer;
  final double totalSales;
  final double totalCash;
  final double totalUpi;
  final int totalDelivered;
  final int totalReturned;
  final int totalDeliveriesCount;
  final String? errorMessage;
  final int currentStock;
  final String? selectedZone;
  final String? selectedSalesmanId;
  final List<Customer> filteredCustomers;
  final bool isAgencyView;

  const DeliveryState({
    this.status = DeliveryStatus.initial,
    this.customers = const [],
    this.todayTransactions = const [],
    this.allTodayTransactions = const [],
    this.selectedCustomer,
    this.totalSales = 0,
    this.totalCash = 0,
    this.totalUpi = 0,
    this.totalDelivered = 0,
    this.totalReturned = 0,
    this.totalDeliveriesCount = 0,
    this.errorMessage,
    this.currentStock = 0,
    this.selectedZone,
    this.selectedSalesmanId,
    this.filteredCustomers = const [],
    this.isAgencyView = false,
  });

  DeliveryState copyWith({
    DeliveryStatus? status,
    List<Customer>? customers,
    List<TransactionEntity>? todayTransactions,
    List<TransactionEntity>? allTodayTransactions,
    Customer? selectedCustomer,
    bool clearSelectedCustomer = false,
    double? totalSales,
    double? totalCash,
    double? totalUpi,
    int? totalDelivered,
    int? totalReturned,
    int? totalDeliveriesCount,
    String? errorMessage,
    int? currentStock,
    String? selectedZone,
    bool clearSelectedZone = false,
    String? selectedSalesmanId,
    bool clearSelectedSalesman = false,
    List<Customer>? filteredCustomers,
    bool? isAgencyView,
  }) {
    return DeliveryState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      todayTransactions: todayTransactions ?? this.todayTransactions,
      allTodayTransactions: allTodayTransactions ?? this.allTodayTransactions,
      selectedCustomer: clearSelectedCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      totalSales: totalSales ?? this.totalSales,
      totalCash: totalCash ?? this.totalCash,
      totalUpi: totalUpi ?? this.totalUpi,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      totalReturned: totalReturned ?? this.totalReturned,
      totalDeliveriesCount: totalDeliveriesCount ?? this.totalDeliveriesCount,
      errorMessage: errorMessage ?? this.errorMessage,
      currentStock: currentStock ?? this.currentStock,
      selectedZone: clearSelectedZone ? null : (selectedZone ?? this.selectedZone),
      selectedSalesmanId: clearSelectedSalesman ? null : (selectedSalesmanId ?? this.selectedSalesmanId),
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      isAgencyView: isAgencyView ?? this.isAgencyView,
    );
  }

  @override
  List<Object?> get props => [
        status,
        customers,
        todayTransactions,
        allTodayTransactions,
        selectedCustomer,
        totalSales,
        totalCash,
        totalUpi,
        totalDelivered,
        totalReturned,
        totalDeliveriesCount,
        errorMessage,
        currentStock,
        selectedZone,
        selectedSalesmanId,
        filteredCustomers,
        isAgencyView,
      ];
}
