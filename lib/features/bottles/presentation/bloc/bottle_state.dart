import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

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

  const BottleLoaded({
    required this.customers,
    this.salesmen = const [],
    required this.totalBottles,
    required this.highBalanceCount,
    required this.avgBalance,
    super.isAgencyView,
  });

  @override
  List<Object?> get props => [customers, salesmen, totalBottles, highBalanceCount, avgBalance, isAgencyView];
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
