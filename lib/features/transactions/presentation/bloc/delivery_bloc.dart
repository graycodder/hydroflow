import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  
  StreamSubscription? _customersSubscription;
  StreamSubscription? _transactionsSubscription;

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
    on<DeliveryDataUpdated>(_onDeliveryDataUpdated);
  }

  Future<void> _onLoadDeliveryPage(
    LoadDeliveryPage event,
    Emitter<DeliveryState> emit,
  ) async {
    emit(state.copyWith(status: DeliveryStatus.loading));
    
    // Cancel any existing subscriptions
    await _customersSubscription?.cancel();
    await _transactionsSubscription?.cancel();

    // Initialize Streams
    // Strategy: We listen to both. When EITHER updates, we re-calculate stats.
    // However, we need access to the "latest" of the OTHER stream to calculate stats correctly.
    // Since we don't have rxdart CombineLatest, we can just rely on the BLoC state!
    // The state effectively holds the "latest known" list of customers and transactions.
    // So when Customers update, we use (New Customers, State Transactions).
    // When Transactions update, we use (State Customers, New Transactions).
    
    // 1. Listen to Customers
    _customersSubscription = _customerRepository.getCustomers(event.salesmanId).listen(
      (customers) {
        add(DeliveryDataUpdated(customers: customers));
      },
      onError: (error) {
        // Handle error via event or directly if possible, but easier to just log or ignore for stream
      }
    );

    // 2. Listen to Transactions
    _transactionsSubscription = _getTodayTransactionsUseCase(event.salesmanId).listen(
      (transactions) {
        add(DeliveryDataUpdated(transactions: transactions));
      },
      onError: (error) {
         // Handle error
      }
    );
  }
  
  Future<void> _onDeliveryDataUpdated(
    DeliveryDataUpdated event,
    Emitter<DeliveryState> emit,
  ) async {
    // Merge new data with current state data
    var customers = event.customers ?? state.customers;
    final transactions = event.transactions ?? state.todayTransactions;
    
    // Fix Dropdown Crash: If customers updated, sync selectedCustomer reference
    Customer? updatedSelectedCustomer = state.selectedCustomer;
    if (event.customers != null && updatedSelectedCustomer != null) {
      // Find the same customer in the NEW list
      updatedSelectedCustomer = customers.cast<Customer?>().firstWhere(
        (c) => c?.id == updatedSelectedCustomer?.id,
        orElse: () => updatedSelectedCustomer, // Fallback to current if missing
      );
    }

    // Calculate stats
    _calculateStats(emit, transactions, customers, updatedSelectedCustomer: updatedSelectedCustomer);
  }
  
  @override
  Future<void> close() {
    _customersSubscription?.cancel();
    _transactionsSubscription?.cancel();
    return super.close();
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
    emit(state.copyWith(status: DeliveryStatus.loading));
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

  void _calculateStats(
    Emitter<DeliveryState> emit,
    List<TransactionEntity> transactions,
    List<Customer> customers, {
    Customer? updatedSelectedCustomer,
  }) {
    double sales = 0;
    double cash = 0;
    double upi = 0;
    int delivered = 0;
    int returned = 0;

    final txList = transactions.cast<dynamic>(); 

    for (var tx in txList) {
       // Assuming tx is TransactionEntity
       // But we need to be careful with casting if mocks/tests differ.
       // In real code:
       sales += tx.amount;
       if (tx.paymentMode == 'Cash') cash += tx.amount;
       if (tx.paymentMode == 'UPI') upi += tx.amount;
       delivered += tx.cansDelivered as int;
       returned += tx.emptyCollected as int;
    }

    emit(state.copyWith(
      status: DeliveryStatus.success,
      customers: customers.cast(),
      todayTransactions: txList.cast(),
      selectedCustomer: updatedSelectedCustomer, // Sync the reference
      totalSales: sales,
      totalCash: cash,
      totalUpi: upi,
      totalDelivered: delivered,
      totalReturned: returned,
    ));
  }
}
