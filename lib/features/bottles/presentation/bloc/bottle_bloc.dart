import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/bottles/domain/usecases/get_bottle_ledger_usecase.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_event.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_state.dart';
import 'package:hydroflow/features/bottles/domain/entities/bottle_ledger_stats.dart';
import 'package:hydroflow/features/customers/domain/entities/customer.dart';

class BottleBloc extends Bloc<BottleEvent, BottleState> {
  final GetBottleLedgerUseCase _getBottleLedger;

  BottleBloc({required GetBottleLedgerUseCase getBottleLedger})
      : _getBottleLedger = getBottleLedger,
        super(BottleInitial()) {
    on<LoadBottleLedger>(_onLoadBottleLedger);
    on<LoadAgencyBottleLedger>(_onLoadAgencyBottleLedger);
  }

  Future<void> _onLoadBottleLedger(
    LoadBottleLedger event,
    Emitter<BottleState> emit,
  ) async {
    emit(const BottleLoading(isAgencyView: false));
    await emit.forEach<BottleLedgerStats>(
      _getBottleLedger(event.salesmanId),
      onData: (stats) => BottleLoaded(
        customers: stats.customers,
        totalBottles: stats.totalBottles,
        highBalanceCount: stats.highBalanceCount,
        avgBalance: stats.avgBalance,
        isAgencyView: false,
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
      _getBottleLedger.getAgencyBottleLedger(event.agencyId),
      onData: (stats) => BottleLoaded(
        customers: stats.customers,
        totalBottles: stats.totalBottles,
        highBalanceCount: stats.highBalanceCount,
        avgBalance: stats.avgBalance,
        isAgencyView: true,
      ),
      onError: (e, stackTrace) => BottleFailure('Failed to load agency bottle ledger: $e', isAgencyView: true),
    );
  }
}
