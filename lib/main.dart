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
import 'package:hydroflow/features/auth/presentation/bloc/auth_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Assuming firebase_options.dart exists or will be generated)
  // If not generated, user needs to run flutterfire configure.
  // For now we will try-catch or just put a comment if the file doesn't exist.
  // We'll trust the user has the options file or we can initialize without it for web.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Fallback or just log if options not found (dev mode)
    await Firebase.initializeApp();
  }

  await di.init();

  runApp(const HydroFlowApp());
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
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<NotificationBloc>().add(LoadNotifications(state.salesman.id));
          } else if (state is AuthSubscriptionExpired) {
            router.go('/lock', extra: state.salesman);
          } else if (state is AuthUnauthenticated) {
             router.go('/login');
          }
        },
        child: MaterialApp.router(
          title: 'HydroFlow Pro',
          debugShowCheckedModeBanner: false,
          theme: CodeTheme.lightTheme,
          routerConfig: router,
        ),
      ),
    );
  }
}
