import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/subscription/domain/entities/plan.dart';
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
    await emit.forEach<List<Plan>>(
      _getPlans(),
      onData: (plans) => SubscriptionLoaded(plans),
      onError: (e, stackTrace) => SubscriptionError(e.toString()),
    );
  }
}
