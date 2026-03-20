import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:watermemo/features/bottles/domain/usecases/get_bottle_ledger_usecase.dart';
import 'package:watermemo/features/bottles/presentation/bloc/bottle_event.dart';
import 'package:watermemo/features/bottles/presentation/bloc/bottle_state.dart';
import 'package:watermemo/features/bottles/domain/entities/bottle_ledger_stats.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';

import 'package:watermemo/features/bottles/domain/usecases/get_salesman_bottle_ledger_usecase.dart';

class BottleBloc extends Bloc<BottleEvent, BottleState> {
  final GetBottleLedgerUseCase _getBottleLedger;
  final GetSalesmanBottleLedgerUseCase? _getSalesmanBottleLedger;

  BottleBloc({
    required GetBottleLedgerUseCase getBottleLedger,
    GetSalesmanBottleLedgerUseCase? getSalesmanBottleLedger,
  })  : _getBottleLedger = getBottleLedger,
        _getSalesmanBottleLedger = getSalesmanBottleLedger,
        super(BottleInitial()) {
    on<BottleStreamEvent>(
      (event, emit) async {
        if (event is LoadBottleLedger) {
          await _onLoadBottleLedger(event, emit);
        } else if (event is LoadAgencyBottleLedger) {
          await _onLoadAgencyBottleLedger(event, emit);
        } else if (event is LoadSalesmanBottleLedger) {
          await _onLoadSalesmanBottleLedger(event, emit);
        }
      },
      transformer: (events, mapper) => events.switchMap(mapper),
    );

    on<LoadMoreBottleLedger>(_onLoadMoreBottleLedger);
  }

  Future<void> _onLoadMoreBottleLedger(
    LoadMoreBottleLedger event,
    Emitter<BottleState> emit,
  ) async {
    final currentState = state;
    if (currentState is BottleLoaded && !currentState.hasReachedMax && !currentState.isFetchingMore) {
      try {
        emit(currentState.copyWith(isFetchingMore: true));
        
        final lastCustomer = currentState.customers.isNotEmpty ? currentState.customers.last : null;
        final stats = await _getBottleLedger.getPaginatedLedger(
          event.salesmanId,
          agencyId: event.agencyId,
          zone: event.zone,
          lastCustomerId: lastCustomer?.id,
          limit: 20,
        );

        emit(currentState.copyWith(
          customers: List.of(currentState.customers)..addAll(stats.customers),
          hasReachedMax: stats.customers.length < 20,
          isFetchingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isFetchingMore: false));
      }
    }
  }


  Future<void> _onLoadBottleLedger(
    LoadBottleLedger event,
    Emitter<BottleState> emit,
  ) async {
    emit(const BottleLoading(isAgencyView: false));
    await emit.forEach<BottleLedgerStats>(
      _getBottleLedger(event.salesmanId, agencyId: event.agencyId, zone: event.zone),
      onData: (stats) => BottleLoaded(
        customers: stats.customers.length > 20 ? stats.customers.sublist(0, 20) : stats.customers,
        totalBottles: stats.totalBottles,
        highBalanceCount: stats.highBalanceCount,
        avgBalance: stats.avgBalance,
        isAgencyView: false,
        hasReachedMax: stats.customers.length <= 20,
      ),
      onError: (e, stackTrace) => BottleFailure('Failed to load bottle ledger: $e', isAgencyView: false),
    );
  }

  Future<void> _onLoadAgencyBottleLedger(
    LoadAgencyBottleLedger event,
    Emitter<BottleState> emit,
  ) async {
    emit(const BottleLoading(isAgencyView: true));
    await emit.forEach<BottleLedgerStats>(
      _getBottleLedger.getAgencySalesmanLedger(event.agencyId),
      onData: (stats) => BottleLoaded(
        customers: stats.customers.length > 20 ? stats.customers.sublist(0, 20) : stats.customers,
        salesmen: stats.salesmen ?? [],
        totalBottles: stats.totalBottles,
        highBalanceCount: stats.highBalanceCount,
        avgBalance: stats.avgBalance,
        isAgencyView: true,
        hasReachedMax: stats.customers.length <= 20,
      ),
      onError: (e, stackTrace) => BottleFailure('Failed to load agency bottle ledger: $e', isAgencyView: true),
    );
  }

  Future<void> _onLoadSalesmanBottleLedger(
    LoadSalesmanBottleLedger event,
    Emitter<BottleState> emit,
  ) async {
    if (_getSalesmanBottleLedger == null) {
      emit(const BottleFailure("Salesman ledger not supported in this configuration."));
      return;
    }

    emit(const BottleLoading());
    await emit.forEach(
      _getSalesmanBottleLedger!(event.salesmanId, event.date),
      onData: (stats) => SalesmanBottleLoaded(
        salesmanLedgerStats: stats,
        date: event.date,
      ),
      onError: (e, stackTrace) => BottleFailure('Failed to load detailed salesman ledger: $e'),
    );
  }
}
