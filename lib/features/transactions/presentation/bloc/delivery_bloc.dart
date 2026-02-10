import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_event.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_state.dart';
import 'package:hydroflow/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:hydroflow/features/transactions/domain/usecases/get_today_transactions_usecase.dart';
import 'package:hydroflow/features/transactions/domain/entities/transaction_entity.dart';
import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final AddTransactionUseCase _addTransactionUseCase;
  final GetTodayTransactionsUseCase _getTodayTransactionsUseCase;
  final CustomerRepository _customerRepository;
  
  DeliveryBloc({
    required AddTransactionUseCase addTransactionUseCase,
    required GetTodayTransactionsUseCase getTodayTransactionsUseCase,
    required CustomerRepository customerRepository,
  })  : _addTransactionUseCase = addTransactionUseCase,
        _getTodayTransactionsUseCase = getTodayTransactionsUseCase,
        _customerRepository = customerRepository,
        super(const DeliveryState()) {
    on<LoadDeliveryPage>(_onLoadDeliveryPage);
    on<SelectCustomer>(_onSelectCustomer);
    on<SubmitTransaction>(_onSubmitTransaction);
  }

  Future<void> _onLoadDeliveryPage(
    LoadDeliveryPage event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(state.copyWith(
      status: DeliveryStatus.loading,
      clearSelectedCustomer: true,
    ));
    
    final customerStream = _customerRepository.getCustomers(event.salesmanId);
    final transactionStream = _getTodayTransactionsUseCase(event.salesmanId);

    await emit.forEach<Map<String, dynamic>>(
      CombineLatestStream.combine2<List<Customer>, List<TransactionEntity>, Map<String, dynamic>>(
        customerStream,
        transactionStream,
        (customers, transactions) => {
          'customers': customers,
          'transactions': transactions,
        },
      ),
      onData: (data) {
        final customers = data['customers'] as List<Customer>;
        final transactions = data['transactions'] as List<TransactionEntity>;

        // Handle Dropdown Sync: If customers updated, sync selectedCustomer reference
        Customer? updatedSelectedCustomer = state.selectedCustomer;
        if (updatedSelectedCustomer != null) {
          updatedSelectedCustomer = customers.cast<Customer?>().firstWhere(
            (c) => c?.id == updatedSelectedCustomer?.id,
            orElse: () => updatedSelectedCustomer,
          );
        }

        return _calculateUpdatedState(transactions, customers, updatedSelectedCustomer: updatedSelectedCustomer);
      },
      onError: (e, stackTrace) => state.copyWith(
        status: DeliveryStatus.failure,
        errorMessage: e.toString(),
      ),
    );
  }
  
  void _onSelectCustomer(
    SelectCustomer event,
    Emitter<DeliveryState> emit,
  ) {
    emit(state.copyWith(selectedCustomer: event.customer));
  }

  Future<void> _onSubmitTransaction(
    SubmitTransaction event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(state.copyWith(status: DeliveryStatus.submitting));
    try {
      await _addTransactionUseCase(event.transaction);
      
      // Reloading is now automatic via Stream!
      // We don't need to manually fetch.
      // But we might want to clear selection.
      
      // Usually stream update arrives slightly later.
      // We can just emit success status.
      
      // Clear selection handled by UI or we can clear it here?
      // Usually better to clear selection after success.
      emit(state.copyWith(
        status: DeliveryStatus.submissionSuccess,
        clearSelectedCustomer: true,
      )); 

    } catch (e) {
      emit(state.copyWith(
        status: DeliveryStatus.failure,
        errorMessage: "Transaction Failed: ${e.toString()}",
      ));
    }
  }

  DeliveryState _calculateUpdatedState(
    List<TransactionEntity> transactions,
    List<Customer> customers, {
    Customer? updatedSelectedCustomer,
  }) {
    double sales = 0;
    double cash = 0;
    double upi = 0;
    int delivered = 0;
    int returned = 0;

    for (var tx in transactions) {
       // Today's Sales should be based on actual amount RECEIVED (Cash + Online)
       // tx.amount is the total bill value, but sales metric usually means revenue collected.
       sales += tx.amountReceived;
       if (tx.paymentMode == 'Cash') cash += tx.amountReceived;
       if (tx.paymentMode == 'UPI' || tx.paymentMode == 'Online') upi += tx.amountReceived;
       delivered += tx.cansDelivered;
       returned += tx.emptyCollected;
    }

    return state.copyWith(
      status: state.status == DeliveryStatus.submitting ? DeliveryStatus.submitting : DeliveryStatus.success,
      customers: customers,
      todayTransactions: transactions,
      selectedCustomer: updatedSelectedCustomer, // Sync the reference
      totalSales: sales,
      totalCash: cash,
      totalUpi: upi,
      totalDelivered: delivered,
      totalReturned: returned,
    );
  }
}
