import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watermemo/features/transactions/presentation/bloc/delivery_event.dart';
import 'package:watermemo/features/transactions/presentation/bloc/delivery_state.dart';
import 'package:watermemo/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:watermemo/features/transactions/domain/usecases/get_today_transactions_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/search_customers_usecase.dart';
import 'package:watermemo/features/transactions/domain/entities/transaction_entity.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/stock/domain/repositories/inventory_repository.dart';

import 'package:watermemo/features/auth/domain/repositories/auth_repository.dart';
import 'package:watermemo/features/auth/domain/repositories/agency_repository.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final AddTransactionUseCase _addTransactionUseCase;
  final GetTodayTransactionsUseCase _getTodayTransactionsUseCase;
  final CustomerRepository _customerRepository;
  final AuthRepository _authRepository;
  final AgencyRepository _agencyRepository;
  final InventoryRepository _inventoryRepository;
  final SearchCustomersUseCase _searchCustomersUseCase;
  final SharedPreferences _prefs;

  static const String prefZoneKey = 'PREF_SELECTED_ZONE_DELIVERY';
  static const String prefSalesmanKey = 'PREF_SELECTED_SALESMAN_DELIVERY';
  
  DeliveryBloc({
    required AddTransactionUseCase addTransactionUseCase,
    required GetTodayTransactionsUseCase getTodayTransactionsUseCase,
    required SearchCustomersUseCase searchCustomersUseCase,
    required CustomerRepository customerRepository,
    required AuthRepository authRepository,
    required AgencyRepository agencyRepository,
    required InventoryRepository inventoryRepository,
    required SharedPreferences prefs,
  })  : _addTransactionUseCase = addTransactionUseCase,
        _getTodayTransactionsUseCase = getTodayTransactionsUseCase,
        _searchCustomersUseCase = searchCustomersUseCase,
        _customerRepository = customerRepository,
        _authRepository = authRepository,
        _agencyRepository = agencyRepository,
        _inventoryRepository = inventoryRepository,
        _prefs = prefs,
        super(const DeliveryState()) {
    on<DeliveryStreamEvent>(
      (event, emit) async {
        if (event is LoadDeliveryPage) {
          await _onLoadDeliveryPage(event, emit);
        } else if (event is LoadAgencyDeliveries) {
          await _onLoadAgencyDeliveries(event, emit);
        }
      },
      transformer: (events, mapper) => events.switchMap(mapper),
    );
    on<SelectCustomer>(_onSelectCustomer);
    on<SubmitTransaction>(_onSubmitTransaction);
    on<FilterDeliveryByZone>(_onFilterDeliveryByZone);
    on<FilterDeliveryBySalesman>(_onFilterBySalesman);
    on<ResetDeliveryStatus>((event, emit) => emit(state.copyWith(status: DeliveryStatus.success)));
    on<ClearDeliveryFilters>(_onClearFilters);
  }

  void _onClearFilters(
    ClearDeliveryFilters event,
    Emitter<DeliveryState> emit,
  ) {
    // Immediate refresh with no filters
    final filtered = _applyFilters(state.customers, state.allTodayTransactions, null, null);
    emit(state.copyWith(
      clearSelectedZone: true,
      clearSelectedSalesman: true,
      clearSelectedCustomer: true,
      filteredCustomers: filtered['customers'] as List<Customer>,
      todayTransactions: filtered['transactions'] as List<TransactionEntity>,
    ));
  }

  Future<void> _onLoadDeliveryPage(
    LoadDeliveryPage event,
    Emitter<DeliveryState> emit,
  ) async {
    if (event.resetFilters) {
      await _prefs.remove(prefZoneKey);
      await _prefs.remove(prefSalesmanKey);
    }

    final savedZone = event.resetFilters ? null : _prefs.getString(prefZoneKey);
    final savedSalesman = event.resetFilters ? null : _prefs.getString(prefSalesmanKey);

    emit(state.copyWith(
      status: DeliveryStatus.loading,
      clearSelectedCustomer: true,
      selectedZone: savedZone,
      clearSelectedZone: savedZone == null,
      selectedSalesmanId: event.salesmanId, // Ensure state has the current salesman ID
      clearSelectedSalesman: false,
      isAgencyView: false,
      agencyId: event.agencyId,
    ));
    
    final salesmanStream = _authRepository.getSalesmanStream(event.salesmanId);

    await emit.forEach<Map<String, dynamic>>(
      salesmanStream.switchMap((salesman) {
        // Only load customers for THIS specific salesman to keep it fast
        final customerStream = _customerRepository.getCustomers(
          event.salesmanId,
          agencyId: event.agencyId,
        );
        final transactionStream = _getTodayTransactionsUseCase(event.salesmanId);
        final stockStream = Stream.value(salesman.currentStock);

        return CombineLatestStream.combine3<List<Customer>, List<TransactionEntity>, int, Map<String, dynamic>>(
          customerStream,
          transactionStream,
          stockStream,
          (customers, transactions, currentStock) => {
            'customers': customers,
            'transactions': transactions,
            'currentStock': currentStock,
          },
        );
      }),
      onData: (data) {
        final customers = data['customers'] as List<Customer>;
        final transactions = data['transactions'] as List<TransactionEntity>;
        final currentStock = data['currentStock'] as int;

        return _calculateUpdatedState(transactions, customers, currentStock).copyWith(
          isAgencyView: false,
          agencyId: event.agencyId,
        );
      },
      onError: (e, stackTrace) => state.copyWith(
        status: DeliveryStatus.failure,
        errorMessage: e.toString(),
      ),
    );
  }

  Future<void> _onLoadAgencyDeliveries(
    LoadAgencyDeliveries event,
    Emitter<DeliveryState> emit,
  ) async {
    if (event.resetFilters) {
      await _prefs.remove(prefZoneKey);
      await _prefs.remove(prefSalesmanKey);
    }

    final savedZone = event.resetFilters ? null : _prefs.getString(prefZoneKey);
    final savedSalesman = event.resetFilters ? null : _prefs.getString(prefSalesmanKey);

    emit(state.copyWith(
      status: DeliveryStatus.loading,
      clearSelectedCustomer: true,
      selectedZone: savedZone,
      clearSelectedZone: savedZone == null,
      selectedSalesmanId: savedSalesman,
      clearSelectedSalesman: savedSalesman == null,
      isAgencyView: true,
    ));

    // Get all salesmen for this agency to aggregate transactions
    final salesmenStream = Stream.fromFuture(_agencyRepository.getSalesmenByAgency(event.agencyId));
    
    await emit.forEach<Map<String, dynamic>>(
      salesmenStream.switchMap((salesmen) {
        final ids = salesmen.map((s) => s.id).toList();
        
        final transactionStream = _getTodayTransactionsUseCase.byAgency(ids);
        final stockStream = _inventoryRepository.getAgencyWarehouseStock(event.agencyId).map((s) => s['fullBottles'] ?? 0);

        return CombineLatestStream.combine2<List<TransactionEntity>, int, Map<String, dynamic>>(
          transactionStream,
          stockStream,
          (transactions, currentStock) => {
            'transactions': transactions,
            'currentStock': currentStock,
          },
        );
      }),
      onData: (data) {
        final customers = <Customer>[]; 
        final transactions = data['transactions'] as List<TransactionEntity>;
        final currentStock = data['currentStock'] as int;

        return _calculateUpdatedState(transactions, customers, currentStock).copyWith(
          isAgencyView: true,
          agencyId: event.agencyId,
        );
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

  void _onFilterDeliveryByZone(
    FilterDeliveryByZone event,
    Emitter<DeliveryState> emit,
  ) {
    // If selecting the same zone, clear it
    final newZone = event.zone;
    
    // Persist selection
    if (newZone == null) {
      _prefs.remove(prefZoneKey);
    } else {
      _prefs.setString(prefZoneKey, newZone);
    }

    final filtered = _applyFilters(state.customers, state.allTodayTransactions, newZone, state.selectedSalesmanId);
    emit(state.copyWith(
      selectedZone: newZone,
      clearSelectedZone: newZone == null,
      filteredCustomers: filtered['customers'] as List<Customer>,
      todayTransactions: filtered['transactions'] as List<TransactionEntity>,
      clearSelectedCustomer: true, // Clear selected customer when filtering changes
    ));
  }

  void _onFilterBySalesman(
    FilterDeliveryBySalesman event,
    Emitter<DeliveryState> emit,
  ) {
    final newSalesmanId = event.salesmanId;
    
    // Persist selection
    if (newSalesmanId == null) {
      _prefs.remove(prefSalesmanKey);
    } else {
      _prefs.setString(prefSalesmanKey, newSalesmanId);
    }
    
    final filtered = _applyFilters(state.customers, state.allTodayTransactions, state.selectedZone, newSalesmanId);
    emit(state.copyWith(
      selectedSalesmanId: newSalesmanId,
      clearSelectedSalesman: newSalesmanId == null,
      filteredCustomers: filtered['customers'] as List<Customer>,
      todayTransactions: filtered['transactions'] as List<TransactionEntity>,
      clearSelectedCustomer: true,
    ));
  }

  Map<String, dynamic> _applyFilters(List<Customer> customers, List<TransactionEntity> transactions, String? zone, String? salesmanId) {
    final filteredCustomers = customers.where((c) {
      final matchesZone = zone == null || c.zone.toLowerCase() == zone.toLowerCase();
      final matchesSalesman = salesmanId == null || c.salesmanId == salesmanId;
      return matchesZone && matchesSalesman;
    }).toList();

    final filteredTransactions = transactions.where((tx) {
      final matchesSalesman = salesmanId == null || tx.salesmanId == salesmanId;
      
      // Filter by Zone if selected
      bool matchesZone = true;
      if (zone != null) {
        final customer = customers.cast<Customer?>().firstWhere(
          (c) => c?.id == tx.customerId,
          orElse: () => null,
        );
        matchesZone = customer?.zone.toLowerCase() == zone.toLowerCase();
      }
      
      return matchesSalesman && matchesZone;
    }).toList();

    // Sort alphabetically by name
    filteredCustomers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    
    return {
      'customers': filteredCustomers,
      'transactions': filteredTransactions,
    };
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
    List<Customer> customers, 
    int currentStock, {
    Customer? updatedSelectedCustomer,
  }) {
    String? validatedZone = state.selectedZone;
    String? validatedSalesmanId = state.selectedSalesmanId;

    // stats now based on UNFILTERED transactions
    double sales = 0;
    double cash = 0;
    double upi = 0;
    int delivered = 0;
    int returned = 0;
    int deliveryCount = 0;

    for (var tx in transactions) {
       if (tx.type != 'Deposit' && tx.type != 'Refund') {
         sales += tx.amount;
         if (tx.paymentMode == 'Cash') cash += tx.amountReceived;
         if (tx.paymentMode == 'UPI' || tx.paymentMode == 'Online') upi += tx.amountReceived;
       }
       
       delivered += tx.cansDelivered;
       returned += tx.emptyCollected;
       
       if (tx.cansDelivered > 0) {
         deliveryCount++;
       }
    }

    // Filters for transactions list (today's work)
    final filteredTransactions = transactions.where((tx) {
      final matchesSalesman = validatedSalesmanId == null || tx.salesmanId == validatedSalesmanId;
      
      bool matchesZone = true;
      if (validatedZone != null) {
        final customer = customers.cast<Customer?>().firstWhere(
          (c) => c?.id == tx.customerId,
          orElse: () => null,
        );
        matchesZone = customer?.zone.toLowerCase() == validatedZone.toLowerCase();
      }
      
      return matchesSalesman && matchesZone;
    }).toList();

    return state.copyWith(
      status: state.status == DeliveryStatus.submitting ? DeliveryStatus.submitting : DeliveryStatus.success,
      allTodayTransactions: transactions,
      todayTransactions: filteredTransactions,
      customers: customers,
      filteredCustomers: customers, // Base for search
      selectedCustomer: updatedSelectedCustomer,
      totalSales: sales,
      totalCash: cash,
      totalUpi: upi,
      totalDelivered: delivered,
      totalReturned: returned,
      totalDeliveriesCount: deliveryCount,
      currentStock: currentStock,
      selectedZone: validatedZone,
      clearSelectedZone: validatedZone == null,
      selectedSalesmanId: validatedSalesmanId,
      clearSelectedSalesman: validatedSalesmanId == null,
    );
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final activeCustomers = state.customers.where((c) {
      final isActive = c.status == 'Active';
      final matchesZone = state.selectedZone == null || 
                         c.zone.toLowerCase() == state.selectedZone!.toLowerCase();
      return isActive && matchesZone;
    }).toList();
    
    // If we have customers in memory, use the smarter in-memory search
    if (activeCustomers.isNotEmpty) {
      if (query.isEmpty) return activeCustomers;
        
      final lowerQuery = query.toLowerCase();
      final results = activeCustomers.where((c) {
        return c.name.toLowerCase().contains(lowerQuery) ||
               c.phone.contains(lowerQuery);
      }).toList();

      results.sort((a, b) {
        final aLower = a.name.toLowerCase();
        final bLower = b.name.toLowerCase();
        final aStart = aLower.startsWith(lowerQuery);
        final bStart = bLower.startsWith(lowerQuery);
        if (aStart && !bStart) return -1;
        if (!aStart && bStart) return 1;
        return aLower.compareTo(bLower);
      });
      return results;
    }

    // Otherwise (Scale or Agency View), use server-side search
    return _searchCustomersUseCase(
      query,
      salesmanId: !state.isAgencyView ? (state.selectedSalesmanId ?? '') : state.selectedSalesmanId, 
      agencyId: state.agencyId,
      zone: state.selectedZone,
      limit: 50,
    );
  }
}
