import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/stock/domain/repositories/inventory_repository.dart';
import 'package:hydroflow/features/stock/domain/entities/stock_log.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_event.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final InventoryRepository _inventoryRepository;
  StreamSubscription<StockLog?>? _logSubscription;

  StockBloc({
    required InventoryRepository inventoryRepository,
  })  : _inventoryRepository = inventoryRepository,
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
    _logSubscription = _inventoryRepository
        .getTodayStockLogStream(event.salesmanId)
        .listen((log) {
      add(StockLogUpdated(log));
    });
  }

  void _onStockLogUpdated(
    StockLogUpdated event,
    Emitter<StockState> emit,
  ) {
    emit(StockDataUpdated(event.todayLog));
  }

  Future<void> _onStockLoadRequested(
    StockLoadRequested event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(const StockFailure('Quantity must be greater than 0'));
      return;
    }

    emit(StockLoading(todayLog: state.todayLog));
    try {
      await _inventoryRepository.addStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Stock loaded successfully', todayLog: state.todayLog));
    } catch (e) {
      emit(StockFailure('Failed to load stock: $e', todayLog: state.todayLog));
    }
  }

  Future<void> _onStockDamagedReported(
    StockDamagedReported event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(const StockFailure('Quantity must be greater than 0'));
      return;
    }

    emit(StockLoading(todayLog: state.todayLog));
    try {
      await _inventoryRepository.recordDamagedStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Damaged stock recorded', todayLog: state.todayLog));
    } catch (e) {
      emit(StockFailure('Failed to record damaged stock: $e', todayLog: state.todayLog));
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
    emit(StockLoading(todayLog: state.todayLog));
    try {
      await _inventoryRepository.setOpeningStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Opening stock fixed', todayLog: state.todayLog));
    } catch (e) {
      emit(StockFailure('Failed to set opening stock: $e', todayLog: state.todayLog));
    }
  }

  Future<void> _onStockReconciled(
    StockReconciled event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading(todayLog: state.todayLog));
    try {
      await _inventoryRepository.reconcileStock(
        salesmanId: event.salesmanId,
        physicalCount: event.physicalCount,
      );
      emit(StockActionSuccess('Reconciliation completed', todayLog: state.todayLog));
    } catch (e) {
      emit(StockFailure('Reconciliation failed: $e', todayLog: state.todayLog));
    }
  }
}
