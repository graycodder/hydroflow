import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_event.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<Salesman>? _salesmanSubscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    _authSubscription?.cancel();
    _authSubscription = _authRepository.onAuthStateChanged.listen((uid) {
      if (uid != null) {
        _subscribeToSalesman(uid);
      } else {
        add(const AuthStatusChanged(null));
      }
    });
    // Trigger session restore check
    await _authRepository.restoreSession();
  }

  void _subscribeToSalesman(String uid) {
    _salesmanSubscription?.cancel();
    _salesmanSubscription = _authRepository
        .getSalesmanStream(uid)
        .listen(
          (salesman) {
            add(AuthStatusChanged(salesman));
          },
          onError: (error) {
            add(const AuthStatusChanged(null));
          },
        );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {

    emit(AuthLoading());
    try {
      await _authRepository.signIn(
        username: event.username,
        password: event.password,
      );

    } catch (e) {

      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
  }

  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.salesman != null && event.salesman is Salesman) {
      final salesman = event.salesman as Salesman;
      if (salesman.subscriptionExpiry != null && 
          salesman.subscriptionExpiry!.isBefore(DateTime.now())) {
        emit(AuthSubscriptionExpired(salesman));
      } else {
        emit(AuthAuthenticated(salesman));
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _salesmanSubscription?.cancel();
    return super.close();
  }
}
