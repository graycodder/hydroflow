import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/agency_repository.dart';
import '../../domain/entities/salesman.dart';
import '../../domain/entities/agency.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final AgencyRepository _agencyRepository;
  
  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<Salesman>? _salesmanSubscription;
  StreamSubscription<Agency>? _agencySubscription;

  Salesman? _currentSalesman;
  Agency? _currentAgency;

  AuthBloc({
    required AuthRepository authRepository,
    required AgencyRepository agencyRepository,
  })
    : _authRepository = authRepository,
      _agencyRepository = agencyRepository,
      super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    // 1. Check for mandatory updates
    final updateInfo = await _authRepository.checkVersionUpdate();
    if (updateInfo != null && updateInfo['update_required'] == true) {
      emit(AuthUpdateRequired(updateInfo['update_url'] as String));
      return; // Stop further initialization
    }

    _authSubscription?.cancel();
    _authSubscription = _authRepository.onAuthStateChanged.listen((uid) {
      if (!isClosed) {
        if (uid != null) {
          _subscribeToSalesman(uid);
        } else {
          add(const AuthStatusChanged(null));
        }
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
            if (!isClosed) {
              _currentSalesman = salesman;
              _subscribeToAgency(salesman.agencyId);
              add(AuthStatusChanged(salesman, _currentAgency));
            }
          },
          onError: (error) {
            if (!isClosed) {
              _currentSalesman = null;
              add(const AuthStatusChanged(null, null));
            }
          },
        );
  }

  void _subscribeToAgency(String agencyId) {
    if (_agencySubscription != null && _currentAgency?.id == agencyId) return; // Already subscribed to this agency

    _agencySubscription?.cancel();

    _agencySubscription = _agencyRepository
        .getAgencyStream(agencyId)
        .listen(
          (agency) {
            if (!isClosed) {
              _currentAgency = agency;
              add(AuthStatusChanged(_currentSalesman, agency));
            }
          },
          onError: (error) {
            if (!isClosed) {
              // Ignore agency errors or handle gracefully
            }
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
    final salesman = event.salesman;
    final agency = event.agency;

    if (salesman != null) {
      // Wait for agency data to load to prevent flashing the lock screen
      if (salesman.agencyId.isNotEmpty && agency == null) {
        return;
      }

      final bool isUserExpired = salesman.subscriptionExpiry != null && 
          salesman.subscriptionExpiry!.isBefore(DateTime.now());
      
      // If agency is present but has NO expiry date, treat it as expired.
      final bool isAgencyExpired = agency != null && 
          (agency.subscriptionExpiry == null || agency.subscriptionExpiry!.isBefore(DateTime.now()));

      final bool isAgencyInactive = agency != null && agency.status != 'active';

      // Device ID Check
      final currentDeviceId = await _authRepository.getCurrentDeviceId();
      if (currentDeviceId != null) {
        if (salesman.deviceId == null || 
            salesman.deviceId!.isEmpty || 
            salesman.deviceId != currentDeviceId) {
           add(AuthLogoutRequested());
           return;
        }
      }

      if (!salesman.isActive || isUserExpired || isAgencyInactive || isAgencyExpired) {
        emit(AuthSubscriptionExpired(salesman, agency));
      } else {
        emit(AuthAuthenticated(salesman, agency));
      }
    } else {
      _currentSalesman = null;
      _currentAgency = null;
      _salesmanSubscription?.cancel();
      _salesmanSubscription = null;
      _agencySubscription?.cancel();
      _agencySubscription = null;
      
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _salesmanSubscription?.cancel();
    _agencySubscription?.cancel();
    return super.close();
  }
}
