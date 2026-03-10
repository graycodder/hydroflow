import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:watermemo/features/stock/domain/repositories/inventory_repository.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';
import 'package:watermemo/features/stock/domain/entities/stock_log.dart';
import 'package:watermemo/features/stock/presentation/bloc/stock_event.dart';
import 'package:watermemo/features/stock/presentation/bloc/stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final InventoryRepository _inventoryRepository;
  final CustomerRepository _customerRepository;
  StreamSubscription<StockLog?>? _logSubscription;
  StreamSubscription<Map<String, int>>? _agencyStockSubscription;

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
    on<StockAgencyPurchase>(_onStockAgencyPurchase);
    on<LoadAgencyStock>(_onLoadAgencyStock);
    on<AgencyStockUpdated>(_onAgencyStockUpdated);
    on<AgencyStockOpeningStockSet>(_onAgencyStockOpeningStockSet);
    on<AgencyStockRefillRequested>(_onAgencyStockRefillRequested);
    on<AgencyStockDamagedReported>(_onAgencyStockDamagedReported);
    on<EmptyBottlesCollected>(_onEmptyBottlesCollected);
  }

  Future<void> _onLoadStockPage(
    LoadStockPage event,
    Emitter<StockState> emit,
  ) async {
    _logSubscription?.cancel();
    
    // Check if any logs exist globally for this salesman
    final hasLogs = await _inventoryRepository.checkStockLogsExist(event.salesmanId);
    
    if (isClosed) return;

    // Emit preliminary state
    if (state is StockDataUpdated) {
       emit(StockDataUpdated(todayLog: state.todayLog, hasAnyLogs: hasLogs, agencyStock: state.agencyStock, isAgencyView: false));
    } else {
       emit(StockDataUpdated(todayLog: state.todayLog, hasAnyLogs: hasLogs, agencyStock: state.agencyStock, isAgencyView: false));
    }

    _logSubscription = _inventoryRepository
        .getTodayStockLogStream(event.salesmanId)
        .listen(
      (log) {
        if (!isClosed) {
          add(StockLogUpdated(log));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(StockFailure('Stock Stream Error: $error', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: false));
        }
      },
    );
  }

  void _onStockLogUpdated(
    StockLogUpdated event,
    Emitter<StockState> emit,
  ) {
    // If we get a log, it only counts as "setup done" if openingStock > 0.
    // Otherwise, we preserve the history-based state.hasAnyLogs.
    final hasLogs = (event.todayLog != null && event.todayLog!.openingStock > 0) || state.hasAnyLogs;
    emit(StockDataUpdated(todayLog: event.todayLog, hasAnyLogs: hasLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
  }

  Future<void> _onStockLoadRequested(
    StockLoadRequested event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(StockFailure('Quantity must be greater than 0', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
      return;
    }

    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    try {
      await _inventoryRepository.addStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
        agencyId: event.agencyId,
      );
      emit(StockActionSuccess('Stock loaded successfully', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Failed to load stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }

  Future<void> _onStockDamagedReported(
    StockDamagedReported event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(StockFailure('Quantity must be greater than 0', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
      return;
    }

    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    try {
      await _inventoryRepository.recordDamagedStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Damaged stock recorded', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Failed to record damaged stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }

  Future<void> _onStockOpeningStockSet(
    StockOpeningStockSet event,
    Emitter<StockState> emit,
  ) async {
    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    try {
      await _inventoryRepository.setOpeningStock(
        salesmanId: event.salesmanId,
        quantity: event.quantity,
        agencyId: event.agencyId,
      );
      emit(StockActionSuccess('Opening stock fixed', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Failed to set opening stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }

  Future<void> _onStockReconciled(
    StockReconciled event,
    Emitter<StockState> emit,
  ) async {
    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
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
        // Fail silently on snapshot error
        print('Failed to snapshot bottle balance: $e');
      }

      emit(StockActionSuccess('Reconciliation completed', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Reconciliation failed: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }

  Future<void> _onStockAgencyPurchase(
    StockAgencyPurchase event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(StockFailure('Quantity must be greater than 0', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
      return;
    }

    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    try {
      await _inventoryRepository.addAgencyPurchaseStock(
        agencyId: event.agencyId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Warehouse Purchase Added', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Failed to purchase stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }

  Future<void> _onLoadAgencyStock(
    LoadAgencyStock event,
    Emitter<StockState> emit,
  ) async {
    _agencyStockSubscription?.cancel();
    _logSubscription?.cancel();
    
    // Check for Agency Logs
    final hasLogs = await _inventoryRepository.checkAgencyStockLogsExist(event.agencyId);

    if (isClosed) return;

    emit(StockLoading(todayLog: state.todayLog, hasAnyLogs: hasLogs, agencyStock: state.agencyStock, isAgencyView: true));
    
    // 1. Listen to Agency Log Stream
    _logSubscription = _inventoryRepository
        .getAgencyStockLogStream(event.agencyId)
        .listen(
      (log) {
        if (!isClosed) {
          add(StockLogUpdated(log));
        }
      },
      onError: (error) {
        if (!isClosed) {
           // Log error but don't break the UI completely
           print('Agency Log Stream Error: $error');
        }
      },
    );

    // 2. Listen to Warehouse Stock Stream
    _agencyStockSubscription = _inventoryRepository
        .getAgencyWarehouseStock(event.agencyId)
        .listen(
      (stock) {
        if (!isClosed) {
          add(AgencyStockUpdated(stock));
        }
      },
      onError: (error) {
        if (!isClosed) {
          emit(StockFailure('Agency Stock Error: $error', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: true));
        }
      },
    );
  }

  void _onAgencyStockUpdated(
    AgencyStockUpdated event,
    Emitter<StockState> emit,
  ) {
    emit(StockDataUpdated(
      todayLog: state.todayLog,
      hasAnyLogs: state.hasAnyLogs,
      agencyStock: event.stock,
      isAgencyView: state.isAgencyView,
    ));
  }

  Future<void> _onAgencyStockOpeningStockSet(
    AgencyStockOpeningStockSet event,
    Emitter<StockState> emit,
  ) async {
    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    try {
      await _inventoryRepository.setAgencyOpeningStock(
        agencyId: event.agencyId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Agency Opening Stock Set', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Failed to set opening stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }

  Future<void> _onAgencyStockRefillRequested(
    AgencyStockRefillRequested event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(StockFailure('Quantity must be greater than 0', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
      return;
    }
    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    try {
      await _inventoryRepository.addAgencyRefillStock(
        agencyId: event.agencyId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Refill Successful', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Refill Failed: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }

  Future<void> _onAgencyStockDamagedReported(
    AgencyStockDamagedReported event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(StockFailure('Quantity must be greater than 0', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
      return;
    }
    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    try {
      await _inventoryRepository.recordAgencyDamagedStock(
        agencyId: event.agencyId,
        quantity: event.quantity,
        isFromEmpty: event.isFromEmpty,
      );
      emit(StockActionSuccess('Damaged Stock Recorded', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Failed to record damaged stock: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }

  Future<void> _onEmptyBottlesCollected(
    EmptyBottlesCollected event,
    Emitter<StockState> emit,
  ) async {
    if (event.quantity <= 0) {
      emit(StockFailure('Quantity must be greater than 0', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
      return;
    }
    emit(StockActionLoading(todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    try {
      await _inventoryRepository.collectEmptyBottles(
        salesmanId: event.salesmanId,
        agencyId: event.agencyId,
        quantity: event.quantity,
      );
      emit(StockActionSuccess('Empty Bottles Collected Successfully', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    } catch (e) {
      emit(StockFailure('Collection Failed: $e', todayLog: state.todayLog, hasAnyLogs: state.hasAnyLogs, agencyStock: state.agencyStock, isAgencyView: state.isAgencyView));
    }
  }
}
