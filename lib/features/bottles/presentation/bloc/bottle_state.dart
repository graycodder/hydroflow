import 'package:equatable/equatable.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';

class BottleState extends Equatable {
  final bool isAgencyView;
  const BottleState({this.isAgencyView = false});

  @override
  List<Object?> get props => [isAgencyView];
}

class BottleInitial extends BottleState {
  const BottleInitial({super.isAgencyView});
}

class BottleLoading extends BottleState {
  const BottleLoading({super.isAgencyView});
}

class BottleLoaded extends BottleState {
  final List<Customer> customers;
  final List<Salesman> salesmen;
  final int totalBottles;
  final int highBalanceCount;
  final double avgBalance;

  final bool hasReachedMax;
  final bool isFetchingMore;

  const BottleLoaded({
    required this.customers,
    this.salesmen = const [],
    required this.totalBottles,
    required this.highBalanceCount,
    required this.avgBalance,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
    super.isAgencyView,
  });

  @override
  List<Object?> get props => [customers, salesmen, totalBottles, highBalanceCount, avgBalance, hasReachedMax, isFetchingMore, isAgencyView];

  BottleLoaded copyWith({
    List<Customer>? customers,
    List<Salesman>? salesmen,
    int? totalBottles,
    int? highBalanceCount,
    double? avgBalance,
    bool? hasReachedMax,
    bool? isFetchingMore,
    bool? isAgencyView,
  }) {
    return BottleLoaded(
      customers: customers ?? this.customers,
      salesmen: salesmen ?? this.salesmen,
      totalBottles: totalBottles ?? this.totalBottles,
      highBalanceCount: highBalanceCount ?? this.highBalanceCount,
      avgBalance: avgBalance ?? this.avgBalance,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      isAgencyView: isAgencyView ?? this.isAgencyView,
    );
  }
}

class BottleFailure extends BottleState {
  final String error;

  const BottleFailure(this.error, {super.isAgencyView});

  @override
  List<Object?> get props => [error, isAgencyView];
}

class SalesmanBottleLoaded extends BottleState {
  final dynamic salesmanLedgerStats; // Using dynamic here to avoid importing entity everywhere, but specific is better
  final DateTime date;

  const SalesmanBottleLoaded({
    required this.salesmanLedgerStats,
    required this.date,
    super.isAgencyView = false,
  });

  @override
  List<Object?> get props => [salesmanLedgerStats, date, isAgencyView];
}
