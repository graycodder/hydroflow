import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hydroflow/core/theme.dart';
import 'package:hydroflow/core/service_locator.dart' as di;
import 'package:hydroflow/router/app_router.dart';
import 'package:hydroflow/firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_event.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_bloc.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_bloc.dart';
import 'package:hydroflow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:hydroflow/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:hydroflow/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:hydroflow/features/splash/presentation/widgets/splash_view.dart';
import 'package:hydroflow/core/utils/router_refresh_listenable.dart';
import 'package:hydroflow/core/bloc/connectivity/connectivity_bloc.dart';
import 'package:hydroflow/core/widgets/connectivity_wrapper.dart';


void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _initialized = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Remove native splash immediately to show our spinner
      FlutterNativeSplash.remove();

      // Initialize Firebase
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        await Firebase.initializeApp();
      }

      // Initialize dependencies
      await di.init();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization Error: $_error'),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const MaterialApp(
        title: 'HydroFlow',
        debugShowCheckedModeBanner: false,
        home: SplashView(), // Show pure splash UI while initializing
      );
    }

    return const HydroFlowApp();
  }
}

class HydroFlowApp extends StatelessWidget {
  const HydroFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(AppStarted()),
        ),
        BlocProvider<StockBloc>(create: (_) => di.sl<StockBloc>()),
        BlocProvider<BottleBloc>(create: (_) => di.sl<BottleBloc>()),
        BlocProvider<CustomerBloc>(create: (_) => di.sl<CustomerBloc>()),
        BlocProvider<DeliveryBloc>(create: (_) => di.sl<DeliveryBloc>()),
        BlocProvider<NotificationBloc>(create: (_) => di.sl<NotificationBloc>()),
        BlocProvider<DashboardBloc>(create: (_) => di.sl<DashboardBloc>()),
        BlocProvider<ConnectivityBloc>(create: (_) => di.sl<ConnectivityBloc>()),
      ],

      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Trigger router re-evaluation whenever auth state changes
          routerRefreshListenable.notifyListeners();

          if (state is AuthAuthenticated) {
            context.read<NotificationBloc>().add(LoadNotifications(state.salesman.id));
            context.read<DashboardBloc>().add(LoadDashboard(salesmanId: state.salesman.id));
            // Navigation handled by SplashPage or Router Redirect?
            // Actually, if we use SplashPage, we should rely on SplashPage to navigate once ready.
            // But if the user is already on a page and re-authenticates/logout, we might need global listener.
            // For splash flow, the initial route is /splash.
          } else if (state is AuthSubscriptionExpired) {
            // router.go('/lock', extra: state.salesman); // Handled by Router or SplashPage
          } else if (state is AuthUnauthenticated) {
             // router.go('/login'); // Handled by Router or SplashPage
          } else if (state is AuthUpdateRequired) {
             // router.go('/update'); // Handled by Router or SplashPage
          }
        },
        child: MaterialApp.router(
          title: 'HydroFlow',
          debugShowCheckedModeBanner: false,
          theme: CodeTheme.lightTheme,
          routerConfig: router,
          builder: (context, child) {
            return ConnectivityWrapper(child: child!);
          },
        ),

      ),
    );
  }
}
