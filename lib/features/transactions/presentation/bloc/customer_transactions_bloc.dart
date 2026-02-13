import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/transactions/domain/usecases/get_customer_transactions_usecase.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/customer_transactions_event.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/customer_transactions_state.dart';

class CustomerTransactionsBloc extends Bloc<CustomerTransactionsEvent, CustomerTransactionsState> {
  final GetCustomerTransactionsUseCase _getCustomerTransactionsUseCase;
  StreamSubscription? _transactionsSubscription;

  CustomerTransactionsBloc({
    required GetCustomerTransactionsUseCase getCustomerTransactionsUseCase,
  })  : _getCustomerTransactionsUseCase = getCustomerTransactionsUseCase,
        super(const CustomerTransactionsState()) {
    on<LoadCustomerTransactions>(_onLoadCustomerTransactions);
    on<_UpdateTransactions>(_onUpdateTransactions);
    on<_HandleError>(_onHandleError);
  }

  Future<void> _onLoadCustomerTransactions(
    LoadCustomerTransactions event,
    Emitter<CustomerTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: CustomerTransactionsStatus.loading));
    
    await _transactionsSubscription?.cancel();
    
    _transactionsSubscription = _getCustomerTransactionsUseCase(event.customerId).listen(
      (transactions) {
        add(_UpdateTransactions(transactions));
      },
      onError: (error) {
        add(_HandleError(error.toString()));
      },
    );
  }

  // Internal events for stream updates
  void _onUpdateTransactions(
    _UpdateTransactions event,
    Emitter<CustomerTransactionsState> emit,
  ) {
    emit(state.copyWith(
      status: CustomerTransactionsStatus.success,
      transactions: event.transactions,
    ));
  }

  void _onHandleError(
    _HandleError event,
    Emitter<CustomerTransactionsState> emit,
  ) {
    emit(state.copyWith(
      status: CustomerTransactionsStatus.failure,
      errorMessage: event.error,
    ));
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}

// Internal events
class _UpdateTransactions extends CustomerTransactionsEvent {
  final List<TransactionEntity> transactions;
  const _UpdateTransactions(this.transactions);
}

class _HandleError extends CustomerTransactionsEvent {
  final String error;
  const _HandleError(this.error);
}
