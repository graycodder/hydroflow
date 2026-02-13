import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';

enum CustomerTransactionsStatus { initial, loading, success, failure }

class CustomerTransactionsState extends Equatable {
  final CustomerTransactionsStatus status;
  final List<TransactionEntity> transactions;
  final String? errorMessage;

  const CustomerTransactionsState({
    this.status = CustomerTransactionsStatus.initial,
    this.transactions = const [],
    this.errorMessage,
  });

  CustomerTransactionsState copyWith({
    CustomerTransactionsStatus? status,
    List<TransactionEntity>? transactions,
    String? errorMessage,
  }) {
    return CustomerTransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, transactions, errorMessage];
}
