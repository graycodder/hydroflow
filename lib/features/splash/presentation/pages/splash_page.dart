import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_state.dart';

import 'package:watermemo/features/splash/presentation/widgets/splash_view.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Remove native splash if it's still there (though BootstrapApp might have done it)
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
           context.go('/home'); // Dashboard
        } else if (state is AuthUnauthenticated) {
           context.go('/login');
        } else if (state is AuthSubscriptionExpired) {
           context.go('/lock', extra: state.salesman);
        }
      },
      child: const SplashView(), // Use the shared UI
    );
  }
}
