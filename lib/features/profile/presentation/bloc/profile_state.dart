part of 'profile_bloc.dart';



abstract class ProfileState extends Equatable {
  final bool isAgencyView;
  const ProfileState({this.isAgencyView = false});

  @override
  List<Object?> get props => [isAgencyView];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {
  const ProfileLoading({super.isAgencyView});
}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;
  final List<SubscriptionRecord> subscriptionHistory;
  final Agency? agency;

  const ProfileLoaded(this.profile, this.subscriptionHistory, {this.agency, super.isAgencyView});

  @override
  List<Object?> get props => [profile, subscriptionHistory, agency, isAgencyView];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message, {super.isAgencyView});

  @override
  List<Object?> get props => [message, isAgencyView];
}
