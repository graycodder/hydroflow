import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/stock/domain/repositories/inventory_repository.dart';
import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_event.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final InventoryRepository _inventoryRepository;
  final CustomerRepository _customerRepository;
  StreamSubscription<StockLog?>? _logSubscription;

  StockBloc({
    required InventoryRepository inventoryRepository,
    required CustomerRepository customerRepository,
  })  : _inventoryRepository = inventoryRepository,
        _customerRepository = customerRepository,
        super(const StockInitial()) {
    on<LoadStockPage>(_onLoadStockPage);
    on<StockLoadRequested>(_onStockLoadRequested);
    on<StockDamagedReported>(_onStockDamagedReported);
    on<StockLogUpdated>(_onStockLogUpdated);
    on<StockOpeningStockSet>(_onStockOpeningStockSet);
    on<StockReconciled>(_onStockReconciled);
  }

  Future<void> _onLoadStockPage(
    LoadStockPage event,
    Emitter<StockState> emit,
  ) async {
    _logSubscription?.cancel();
    
    // Check if any logs exist globally for this salesman
    final hasLogs = await _inventoryRepository.checkStockLogsExist(event.salesmanId);
    
    if (isClosed) return;

    // Emit current state with updated hasAnyLogs flag
    // We use StockDataUpdated or just copy current state if possible, but here we likely transition from Initial/Loading
    // Let's assume we are in Loading or Initial. 
    // If we are already listening, we might have a todayLog.
    if (state is StockDataUpdated) {
       emit(StockDataUpdated(todayLog: state.todayLog, hasAnyLogs: hasLogs));
    } else {
       // If we are just starting, we might not have todayLog yet.
       // We can emit a state that has hasAnyLogs set.
       // Actually, we can just let the stream listener handle todayLog updates, 
       // but we need to create a state that holds hasAnyLogs.
       // Let's emit a preliminary update.
       emit(StockDataUpdated(todayLog: state.todayLog, hasAnyLogs: hasLogs));
    }

    _logSubscription = _inventoryRepository
        .getTodayStockLogStream(event.salesmanId)
        .listen((log) {
      if (!isClosed) {
        add(StockLogUpdated(log));
      }
    });
  }

  void _onStockLogUpdated(
    StockLogUpdated event,
    Emitter<StockState> emit,
  ) {
    // If we get a log, it only counts as "setup done" if openingStock > 0.
    // Otherwise, we preserve the history-based state.hasAnyLogs.
    final hasLogs = (event.todayLog != null && event.todayLog!.openingStock > 0) || state.hasAnyLogs;
    emit(StockDataUpdated(todayLog: event.todayLog, hasAnyLogs: hasLogs));

  }

  Future<void> _onStockLoadRequested(
    StockLoadRequested event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(StockFailure('Quantity must be greater than 0', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
      return;
    }

    emit(StockLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    try {
      await _inventoryRepository.addStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Stock loaded successfully', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    } catch (e) {
      emit(StockFailure('Failed to load stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    }
  }

  Future<void> _onStockDamagedReported(
    StockDamagedReported event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(StockFailure('Quantity must be greater than 0', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
      return;
    }

    emit(StockLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    try {
      await _inventoryRepository.recordDamagedStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Damaged stock recorded', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    } catch (e) {
      emit(StockFailure('Failed to record damaged stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    }
  }

  @override
  Future<void> close() {
    _logSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStockOpeningStockSet(
    StockOpeningStockSet event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    try {
      await _inventoryRepository.setOpeningStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Opening stock fixed', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    } catch (e) {
      emit(StockFailure('Failed to set opening stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    }
  }

  Future<void> _onStockReconciled(
    StockReconciled event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    try {
      // 1. Reconcile Stock
      await _inventoryRepository.reconcileStock(
        salesmanId: event.salesmanId,
        physicalCount: event.physicalCount,
      );

      // 2. Snapshot Total Bottles with Customers
      try {
        final totalBottles = await _customerRepository.getTotalBottleBalance(event.salesmanId);
        await _inventoryRepository.recordDailyBottleSnapshot(
          salesmanId: event.salesmanId, 
          totalBottles: totalBottles,
        );
      } catch (e) {
        // Fail silently on snapshot error to not block the main reconciliation flow
        // Just log it or ignore
        print('Failed to snapshot bottle balance: $e');
      }

      emit(StockActionSuccess('Reconciliation completed', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    } catch (e) {
      emit(StockFailure('Reconciliation failed: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs));
    }
  }
}
