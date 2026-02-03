import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/subscription/domain/usecases/get_plans_usecase.dart';
import 'package:hydroflow/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:hydroflow/features/subscription/presentation/bloc/subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetPlansUseCase _getPlans;

  SubscriptionBloc({required GetPlansUseCase getPlans})
      : _getPlans = getPlans,
        super(SubscriptionInitial()) {
    on<LoadPlans>(_onLoadPlans);
  }

  Future<void> _onLoadPlans(
    LoadPlans event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    try {
      final plans = await _getPlans();
      emit(SubscriptionLoaded(plans));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }
}
