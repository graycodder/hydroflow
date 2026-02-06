import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

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

  const AuthSubscriptionExpired(this.salesman);

  @override
  List<Object?> get props => [salesman];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}
