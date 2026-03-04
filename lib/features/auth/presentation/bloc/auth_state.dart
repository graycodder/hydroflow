import 'package:equatable/equatable.dart';
import '../../domain/entities/salesman.dart';
import '../../domain/entities/agency.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Salesman salesman;
  final Agency? agency;
  final Salesman? originalOwner;

  const AuthAuthenticated(this.salesman, [this.agency, this.originalOwner]);

  @override
  List<Object?> get props => [salesman, agency, originalOwner];
}

class AuthUnauthenticated extends AuthState {}

class AuthSubscriptionExpired extends AuthState {
  final Salesman salesman;
  final Agency? agency;
  final Salesman? originalOwner;

  const AuthSubscriptionExpired(this.salesman, [this.agency, this.originalOwner]);

  @override
  List<Object?> get props => [salesman, agency, originalOwner];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthUpdateRequired extends AuthState {
  final String updateUrl;
  final String currentVersion;

  const AuthUpdateRequired(this.updateUrl, this.currentVersion);

  @override
  List<Object?> get props => [updateUrl, currentVersion];
}
