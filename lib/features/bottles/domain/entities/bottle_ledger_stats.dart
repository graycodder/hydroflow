import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

class BottleLedgerStats extends Equatable {
  final List<Customer> customers;
  final List<Salesman>? salesmen;
  final int totalBottles;
  final int highBalanceCount;
  final double avgBalance;

  const BottleLedgerStats({
    required this.customers,
    this.salesmen,
    required this.totalBottles,
    required this.highBalanceCount,
    required this.avgBalance,
  });

  @override
  List<Object?> get props => [customers, salesmen, totalBottles, highBalanceCount, avgBalance];
}
