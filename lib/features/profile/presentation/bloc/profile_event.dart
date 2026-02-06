part of 'profile_bloc.dart';

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
