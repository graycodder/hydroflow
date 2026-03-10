import 'package:equatable/equatable.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/transactions/domain/entities/transaction_entity.dart';

class SalesmanBottleLedgerStats extends Equatable {
  // A. Physical Inventory
  final int openingEmptyBottles;
  final int fullBottlesLoaded;
  final int emptyBottlesReturnedToWarehouse;
  final int currentPhysicalEmptyCount;
  final int currentPhysicalFullCount;

  // B. Daily Market Movement
  final int bottlesDeliveredToday;
  final int bottlesCollectedToday;
  final int netMarketMovement;

  // C. Customer Ledger & Liability
  final int totalBottlesWithCustomers;
  final int highBalanceCount;
  final double averageCustomerHolding;
  final List<Customer> customers;
  
  // D. Leakage & Reconciliation
  final int damagedBottles;
  final int mismatchCount;

  // Raw history
  final List<TransactionEntity> todayTransactions;

  const SalesmanBottleLedgerStats({
    required this.openingEmptyBottles,
    required this.fullBottlesLoaded,
    required this.emptyBottlesReturnedToWarehouse,
    required this.currentPhysicalEmptyCount,
    required this.currentPhysicalFullCount,
    required this.bottlesDeliveredToday,
    required this.bottlesCollectedToday,
    required this.netMarketMovement,
    required this.totalBottlesWithCustomers,
    required this.highBalanceCount,
    required this.averageCustomerHolding,
    required this.customers,
    required this.damagedBottles,
    required this.mismatchCount,
    required this.todayTransactions,
  });

  @override
  List<Object?> get props => [
        openingEmptyBottles,
        fullBottlesLoaded,
        emptyBottlesReturnedToWarehouse,
        currentPhysicalEmptyCount,
        currentPhysicalFullCount,
        bottlesDeliveredToday,
        bottlesCollectedToday,
        netMarketMovement,
        totalBottlesWithCustomers,
        highBalanceCount,
        averageCustomerHolding,
        customers,
        damagedBottles,
        mismatchCount,
        todayTransactions,
      ];
}
