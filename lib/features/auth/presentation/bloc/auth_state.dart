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

  const AuthAuthenticated(this.salesman);

  @override
  List<Object?> get props => [salesman];
}

class AuthUnauthenticated extends AuthState {}

class AuthSubscriptionExpired extends AuthState {
  final Salesman salesman;
  final Agency? agency;

  const AuthSubscriptionExpired(this.salesman, [this.agency]);

  @override
  List<Object?> get props => [salesman, agency];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthUpdateRequired extends AuthState {
  final String updateUrl;

  const AuthUpdateRequired(this.updateUrl);

  @override
  List<Object?> get props => [updateUrl];
}
