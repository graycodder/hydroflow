import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

abstract class BottleState extends Equatable {
  const BottleState();

  @override
  List<Object?> get props => [];
}

class BottleInitial extends BottleState {}

class BottleLoading extends BottleState {}

class BottleLoaded extends BottleState {
  final List<Customer> customers;
  final int totalBottles;
  final int highBalanceCount;
  final double avgBalance;

  const BottleLoaded({
    required this.customers,
    required this.totalBottles,
    required this.highBalanceCount,
    required this.avgBalance,
  });

  @override
  List<Object?> get props => [customers, totalBottles, highBalanceCount, avgBalance];
}

class BottleFailure extends BottleState {
  final String error;

  const BottleFailure(this.error);

  @override
  List<Object?> get props => [error];
}
