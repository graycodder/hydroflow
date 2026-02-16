import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  ConnectivityBloc() : super(const ConnectivityState()) {
    on<ConnectivityChanged>(_onConnectivityChanged);

    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Check if any result is not 'none'
      final isConnected = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
      add(ConnectivityChanged(isConnected));
    });

    // Initial check
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final isConnected = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
    add(ConnectivityChanged(isConnected));
  }

  void _onConnectivityChanged(ConnectivityChanged event, Emitter<ConnectivityState> emit) {
    emit(ConnectivityState(
      status: event.isConnected ? ConnectivityStatus.connected : ConnectivityStatus.disconnected,
    ));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
