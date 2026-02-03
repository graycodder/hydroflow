import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

class BottleLedgerStats extends Equatable {
  final List<Customer> customers;
  final int totalBottles;
  final int highBalanceCount;
  final double avgBalance;

  const BottleLedgerStats({
    required this.customers,
    required this.totalBottles,
    required this.highBalanceCount,
    required this.avgBalance,
  });

  @override
  List<Object?> get props => [customers, totalBottles, highBalanceCount, avgBalance];
}
