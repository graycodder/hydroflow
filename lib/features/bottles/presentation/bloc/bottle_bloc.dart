import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/bottles/domain/usecases/get_bottle_ledger_usecase.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_event.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_state.dart';

class BottleBloc extends Bloc<BottleEvent, BottleState> {
  final GetBottleLedgerUseCase _getBottleLedger;

  BottleBloc({required GetBottleLedgerUseCase getBottleLedger})
      : _getBottleLedger = getBottleLedger,
        super(BottleInitial()) {
    on<LoadBottleLedger>(_onLoadBottleLedger);
  }

  Future<void> _onLoadBottleLedger(
    LoadBottleLedger event,
    Emitter<BottleState> emit,
  ) async {
    emit(BottleLoading());
    try {
      final stats = await _getBottleLedger(event.salesmanId);

      emit(BottleLoaded(
        customers: stats.customers,
        totalBottles: stats.totalBottles,
        highBalanceCount: stats.highBalanceCount,
        avgBalance: stats.avgBalance,
      ));
    } catch (e) {
      emit(BottleFailure('Failed to load bottle ledger: $e'));
    }
  }
}
