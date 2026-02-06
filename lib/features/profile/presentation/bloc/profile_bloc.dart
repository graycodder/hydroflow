import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/profile/domain/entities/profile_entity.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_subscription_history_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase _getProfile;
  final GetSubscriptionHistoryUseCase _getSubscriptionHistory;
  StreamSubscription? _profileSubscription;
  StreamSubscription? _historySubscription;

  ProfileBloc({
    required GetProfileUseCase getProfile,
    required GetSubscriptionHistoryUseCase getSubscriptionHistory,
  })  : _getProfile = getProfile,
        _getSubscriptionHistory = getSubscriptionHistory,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<_InternalUpdate>(_onInternalUpdate);
    on<_InternalError>(_onInternalError);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    
    await _profileSubscription?.cancel();
    await _historySubscription?.cancel();

    final profileStream = _getProfile(event.uid);
    final historyStream = _getSubscriptionHistory(event.uid);

    ProfileEntity? latestProfile;
    List<SubscriptionRecord>? latestHistory;

    _profileSubscription = profileStream.listen(
      (profile) {
        latestProfile = profile;
        add(_InternalUpdate(latestProfile, latestHistory));
      },
      onError: (e) => add(_InternalError(e.toString())),
    );

    _historySubscription = historyStream.listen(
      (history) {
        latestHistory = history;
        add(_InternalUpdate(latestProfile, latestHistory));
      },
      onError: (e) => add(_InternalError(e.toString())),
    );
  }

  void _onInternalUpdate(_InternalUpdate event, Emitter<ProfileState> emit) {
    if (event.profile != null && event.history != null) {
      emit(ProfileLoaded(event.profile!, event.history!));
    }
  }

  void _onInternalError(_InternalError event, Emitter<ProfileState> emit) {
    emit(ProfileError(event.message));
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    _historySubscription?.cancel();
    return super.close();
  }
}
