import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/profile/domain/entities/profile_entity.dart';
import 'package:hydroflow/features/profile/domain/entities/subscription_record.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_subscription_history_usecase.dart';
import 'dart:async';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String uid;
  const LoadProfile(this.uid);
  @override
  List<Object?> get props => [uid];
}

// State
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final List<SubscriptionRecord> subscriptionHistory;
  const ProfileLoaded(this.profile, this.subscriptionHistory);
  @override
  List<Object?> get props => [profile, subscriptionHistory];
}
class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
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

// Internal Events for Stream Updates
class _InternalUpdate extends ProfileEvent {
  final ProfileEntity? profile;
  final List<SubscriptionRecord>? history;
  const _InternalUpdate(this.profile, this.history);
  @override
  List<Object?> get props => [profile, history];
}

class _InternalError extends ProfileEvent {
  final String message;
  const _InternalError(this.message);
  @override
  List<Object?> get props => [message];
}
