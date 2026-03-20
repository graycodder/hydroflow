import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/features/customers/domain/usecases/add_customer_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/update_customer_status_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/settle_customer_usecase.dart';
import 'package:watermemo/features/customers/presentation/bloc/customer_event.dart';
import 'package:watermemo/features/customers/presentation/bloc/customer_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomersUseCase getCustomers;
  final AddCustomerUseCase addCustomer;
  final UpdateCustomerStatusUseCase updateCustomerStatus;
  final UpdateCustomerUseCase updateCustomer;
  final SettleCustomerUseCase settleCustomer;
  final SharedPreferences _prefs;

  static const String prefZoneKey = 'PREF_SELECTED_ZONE_CUSTOMERS';
  static const String prefSalesmanKey = 'PREF_SELECTED_SALESMAN_CUSTOMERS';

  CustomerBloc({
    required this.getCustomers,
    required this.addCustomer,
    required this.updateCustomerStatus,
    required this.updateCustomer,
    required this.settleCustomer,
    required SharedPreferences prefs,
  }) : _prefs = prefs,
       super(const CustomerState()) {
    on<CustomerStreamEvent>(
      (event, emit) async {
        if (event is LoadCustomers) {
          await _onLoadCustomers(event, emit);
        } else if (event is LoadAgencyCustomers) {
          await _onLoadAgencyCustomers(event, emit);
        }
      },
      transformer: (events, mapper) => events.switchMap(mapper),
    );

    on<AddCustomer>(_onAddCustomer);
    on<SearchCustomers>(_onSearchCustomers);
    on<UpdateCustomerStatus>(_onUpdateCustomerStatus);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<SettleCustomer>(_onSettleCustomer);
    on<FilterByZone>(_onFilterByZone);
    on<FilterBySalesman>(_onFilterBySalesman);
    on<ClearCustomerFilters>(_onClearFilters);
    on<LoadMoreCustomers>(_onLoadMoreCustomers);
  }

  void _onClearFilters(
    ClearCustomerFilters event,
    Emitter<CustomerState> emit,
  ) {
    final unfiltered = _applyFilters(state.customers, state.searchQuery, null, null);
    emit(state.copyWith(
      clearSelectedZone: true,
      clearSelectedSalesman: true,
      filteredCustomers: unfiltered,
    ));
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    if (event.resetFilters) {
      await _prefs.remove(prefZoneKey);
      await _prefs.remove(prefSalesmanKey);
    }

    final savedZone = event.resetFilters ? null : _prefs.getString(prefZoneKey);
    // In salesman view, we never filter by another salesman
    emit(state.copyWith(
      status: CustomerStatus.loading,
      selectedZone: savedZone,
      clearSelectedZone: savedZone == null,
      clearSelectedSalesman: true, // Always clear in salesman view
      isAgencyView: false,
    ));
    
    await emit.forEach<List<Customer>>(
      getCustomers(event.salesmanId, agencyId: event.agencyId, zone: event.zone),
      onData: (customers) {
        final sortedCustomers = _applyFilters(customers, state.searchQuery, state.selectedZone, state.selectedSalesmanId);
        
        final isSearching = state.searchQuery.isNotEmpty || state.selectedZone != null;
        final initialCustomers = (isSearching || sortedCustomers.length <= 20) 
            ? sortedCustomers 
            : sortedCustomers.sublist(0, 20);
        
        final activeCount = customers.where((c) => c.status == 'Active').length;
        final inactiveCount = customers.length - activeCount;

        return state.copyWith(
          status: CustomerStatus.success,
          customers: customers, 
          filteredCustomers: initialCustomers, 
          totalCustomers: customers.length,
          activeCustomers: activeCount,
          inactiveCustomers: inactiveCount,
          successMessage: null,
          isAgencyView: false,
          hasReachedMax: isSearching || sortedCustomers.length <= 20,
          isFetchingMore: false,
        );
      },
      onError: (error, stackTrace) => state.copyWith(
        status: CustomerStatus.failure,
        errorMessage: 'Failed to load customers: $error',
        successMessage: null,
      ),
    );
  }

  Future<void> _onLoadAgencyCustomers(
    LoadAgencyCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    if (event.resetFilters) {
      await _prefs.remove(prefZoneKey);
      await _prefs.remove(prefSalesmanKey);
    }

    final savedZone = event.resetFilters ? null : _prefs.getString(prefZoneKey);
    final savedSalesman = event.resetFilters ? null : _prefs.getString(prefSalesmanKey);
    
    emit(state.copyWith(
      status: CustomerStatus.loading,
      selectedZone: savedZone,
      clearSelectedZone: savedZone == null,
      selectedSalesmanId: savedSalesman,
      clearSelectedSalesman: savedSalesman == null,
      isAgencyView: true,
    ));
    
    await emit.forEach<List<Customer>>(
      getCustomers.byAgency(event.agencyId),
      onData: (customers) {
        final sortedCustomers = _applyFilters(customers, state.searchQuery, state.selectedZone, state.selectedSalesmanId);
        
        final isSearching = state.searchQuery.isNotEmpty || state.selectedZone != null || state.selectedSalesmanId != null;
        final initialCustomers = (isSearching || sortedCustomers.length <= 20) 
            ? sortedCustomers 
            : sortedCustomers.sublist(0, 20);

        final activeCount = customers.where((c) => c.status == 'Active').length;
        final inactiveCount = customers.length - activeCount;

        return state.copyWith(
          status: CustomerStatus.success,
          customers: customers,
          filteredCustomers: initialCustomers, 
          totalCustomers: customers.length,
          activeCustomers: activeCount,
          inactiveCustomers: inactiveCount,
          successMessage: null,
          isAgencyView: true,
          hasReachedMax: isSearching || sortedCustomers.length <= 20,
          isFetchingMore: false,
        );
      },
      onError: (error, stackTrace) => state.copyWith(
        status: CustomerStatus.failure,
        errorMessage: 'Failed to load agency customers: $error',
        successMessage: null,
      ),
    );
  }

  Future<void> _onAddCustomer(
    AddCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.submitting, successMessage: null));
    try {
      final newCustomer = Customer(
        id: '', // Generated by Repo/DB
        agencyId: event.agencyId,
        salesmanId: event.salesmanId,
        name: event.name,
        phone: event.phone,
        address: event.address,
        status: 'Active',
        zone: event.zone,
        securityDeposit: event.securityDeposit,
        paymentMode: event.paymentMode,
        createdAt: DateTime.now(),
        updatedId: event.updatedId,
        updateAt: event.updateAt,
      );

      await addCustomer(newCustomer);
      emit(state.copyWith(
        status: CustomerStatus.success, 
        successMessage: 'Customer added successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerStatus.failure,
        errorMessage: 'Failed to add customer: $e',
        successMessage: null,
      ));
    }
  }

  void _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) {
    final filtered = _applyFilters(state.customers, event.query, state.selectedZone, state.selectedSalesmanId);
    
    final isSearching = event.query.isNotEmpty || state.selectedZone != null || state.selectedSalesmanId != null;
    final displayCustomers = (isSearching || filtered.length <= 20) 
        ? filtered 
        : filtered.sublist(0, 20);

    emit(state.copyWith(
      filteredCustomers: displayCustomers, 
      searchQuery: event.query,
      successMessage: null,
      hasReachedMax: isSearching || filtered.length <= 20,
    ));
  }

  void _onFilterByZone(
    FilterByZone event,
    Emitter<CustomerState> emit,
  ) {
    // If selecting the same zone, clear it
    final newZone = state.selectedZone == event.zone ? null : event.zone;
    
    // Persist selection
    if (newZone == null) {
      _prefs.remove(prefZoneKey);
    } else {
      _prefs.setString(prefZoneKey, newZone);
    }

    final filtered = _applyFilters(state.customers, state.searchQuery, newZone, state.selectedSalesmanId);
    
    final isSearching = state.searchQuery.isNotEmpty || newZone != null || state.selectedSalesmanId != null;
    final displayCustomers = (isSearching || filtered.length <= 20) 
        ? filtered 
        : filtered.sublist(0, 20);

    emit(state.copyWith(
      selectedZone: newZone,
      clearSelectedZone: newZone == null,
      filteredCustomers: displayCustomers,
      successMessage: null,
      hasReachedMax: isSearching || filtered.length <= 20,
    ));
  }

  void _onFilterBySalesman(
    FilterBySalesman event,
    Emitter<CustomerState> emit,
  ) {
    final newId = state.selectedSalesmanId == event.salesmanId ? null : event.salesmanId;
    
    // Persist selection
    if (newId == null) {
      _prefs.remove(prefSalesmanKey);
    } else {
      _prefs.setString(prefSalesmanKey, newId);
    }

    final filtered = _applyFilters(state.customers, state.searchQuery, state.selectedZone, newId);
    
    final isSearching = state.searchQuery.isNotEmpty || state.selectedZone != null || newId != null;
    final displayCustomers = (isSearching || filtered.length <= 20) 
        ? filtered 
        : filtered.sublist(0, 20);

    emit(state.copyWith(
      selectedSalesmanId: newId,
      clearSelectedSalesman: newId == null,
      filteredCustomers: displayCustomers,
      successMessage: null,
      hasReachedMax: isSearching || filtered.length <= 20,
    ));
  }

  List<Customer> _applyFilters(List<Customer> customers, String query, String? zone, String? salesmanId) {
    final filtered = customers.where((customer) {
      final matchesSearch = query.isEmpty ||
          customer.name.toLowerCase().contains(query.toLowerCase()) ||
          customer.phone.contains(query.toLowerCase());
      
      final matchesZone = zone == null || customer.zone.toLowerCase() == zone.toLowerCase();
      final matchesSalesman = salesmanId == null || customer.salesmanId == salesmanId;
      
      return matchesSearch && matchesZone && matchesSalesman;
    }).toList();

    // Sort alphabetically by name
    return filtered..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _onUpdateCustomerStatus(
    UpdateCustomerStatus event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.submitting, successMessage: null));
    try {
      await updateCustomerStatus(event.customerId, event.status, event.salesmanId);
      emit(state.copyWith(
        status: CustomerStatus.success, 
        successMessage: 'Status updated successfully',
      ));
    } catch (e) {
       emit(state.copyWith(
        status: CustomerStatus.failure,
        errorMessage: 'Failed to update status: $e',
        successMessage: null,
      ));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.submitting, successMessage: null));
    try {
      await updateCustomer(event.customer);
      emit(state.copyWith(
        status: CustomerStatus.success, 
        successMessage: 'Customer updated successfully',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerStatus.failure,
        errorMessage: 'Failed to update customer: $e',
        successMessage: null,
      ));
    }
  }

  Future<void> _onSettleCustomer(
    SettleCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(status: CustomerStatus.submitting, successMessage: null));
    try {
      await settleCustomer(event.customer);
      emit(state.copyWith(
        status: CustomerStatus.success, 
        successMessage: 'Transaction settled successfully',
      ));
    } catch (e) {
       emit(state.copyWith(
        status: CustomerStatus.failure,
        errorMessage: 'Failed to settle customer: $e',
        successMessage: null,
      ));
    }
  }

  Future<void> _onLoadMoreCustomers(
    LoadMoreCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    // Only load more if not searching and not filtering by zone (since we load all in those cases for now)
    final isSearching = state.searchQuery.isNotEmpty || state.selectedZone != null;
    
    if (state.status == CustomerStatus.success && !state.hasReachedMax && !state.isFetchingMore && !isSearching) {
      emit(state.copyWith(isFetchingMore: true));
      try {
        final lastCustomer = state.filteredCustomers.isNotEmpty ? state.filteredCustomers.last : null;
        final newCustomers = await getCustomers.getCustomersPaginated(
          event.salesmanId,
          agencyId: event.agencyId,
          zone: event.zone,
          lastCustomerId: lastCustomer?.id,
          limit: 20,
        );

        emit(state.copyWith(
          filteredCustomers: List.of(state.filteredCustomers)..addAll(newCustomers),
          hasReachedMax: newCustomers.length < 20,
          isFetchingMore: false,
        ));
      } catch (e) {
        emit(state.copyWith(isFetchingMore: false));
      }
    }
  }
}
