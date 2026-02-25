import 'package:equatable/equatable.dart';
import '../../domain/entities/salesman.dart';
import '../../domain/entities/agency.dart';

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
  final Agency? agency;
  const AuthStatusChanged(this.salesman, [this.agency]);

  @override
  List<Object?> get props => [salesman, agency];
}
