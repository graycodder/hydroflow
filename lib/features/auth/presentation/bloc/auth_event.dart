import 'package:equatable/equatable.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthStatusChanged extends AuthEvent {
  final Salesman? salesman;
  const AuthStatusChanged(this.salesman);

  @override
  List<Object?> get props => [salesman];
}
