import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_state.dart';
import 'package:watermemo/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:watermemo/features/stock/presentation/pages/stock_page.dart';
import 'package:watermemo/features/auth/presentation/pages/login_page.dart';
import 'package:watermemo/features/bottles/presentation/pages/bottles_page.dart';
import 'package:watermemo/features/customers/presentation/pages/customers_page.dart';
import 'package:watermemo/features/transactions/presentation/pages/delivery_page.dart';
import 'package:watermemo/features/reports/presentation/pages/reports_page.dart';
import 'package:watermemo/features/splash/presentation/pages/splash_page.dart';
import 'package:watermemo/features/notifications/presentation/pages/notifications_page.dart';
import 'package:watermemo/features/profile/presentation/pages/subscription_lock_page.dart';
import 'package:watermemo/features/profile/presentation/pages/profile_page.dart';
import 'package:watermemo/features/profile/presentation/pages/terms_and_conditions_page.dart';
import 'package:watermemo/features/profile/presentation/pages/privacy_policy_page.dart';
import 'package:watermemo/features/transactions/presentation/pages/transaction_history_page.dart';
import 'package:watermemo/features/auth/presentation/pages/force_update_page.dart';
import 'package:watermemo/features/auth/domain/entities/salesman.dart';
import 'package:watermemo/features/customers/domain/entities/customer.dart';
import 'package:watermemo/core/utils/router_refresh_listenable.dart';

import 'package:watermemo/features/auth/presentation/pages/agency_employees_page.dart';
import 'package:watermemo/router/route_observer.dart'; // Add this line

final router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: routerRefreshListenable,
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final bool loggingIn = state.matchedLocation == '/login';
    final bool locking = state.matchedLocation == '/lock';
    final bool splashing = state.matchedLocation == '/splash';
    final bool updating = state.matchedLocation == '/update';
    final bool terming = state.matchedLocation == '/terms';
    final bool privying = state.matchedLocation == '/privacy';

    if (authState is AuthUpdateRequired) {
      if (updating) return null;
      return '/update';
    }

    // Allow terms and privacy to be accessed from any state
    if (terming || privying) return null;

    // Allow splash to stay if AuthInitial or AuthLoading (implied by not matching other states)
    if (authState is AuthInitial || authState is AuthLoading) {
      return null; 
    }

    if (authState is AuthUnauthenticated) {
      if (loggingIn || updating) return null;
      return '/login';
    }

    if (authState is AuthSubscriptionExpired) {
      if (locking) return null;
      return '/lock';
    }

    if (authState is AuthAuthenticated) {
      if (loggingIn || locking || splashing || updating) return '/home';
    }

    return null;
  },
  observers: [routeObserver],
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/update',
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthUpdateRequired) {
          return ForceUpdatePage(updateUrl: authState.updateUrl, currentVersion: authState.currentVersion);
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/lock',
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthSubscriptionExpired) {
          return SubscriptionLockPage(
            salesman: authState.salesman,
            agency: authState.agency,
          );
        }
        // Fallback or loading if state hasn't stabilized, 
        // though redirect should handle this.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/stock',
      builder: (context, state) => const StockPage(),
    ),
    GoRoute(
      path: '/bottles',
      builder: (context, state) => const BottlesPage(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersPage(),
    ),
    GoRoute(
      path: '/delivery',
      builder: (context, state) => const DeliveryPage(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsAndConditionsPage(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      path: '/customer_history',
      builder: (context, state) {
        final customer = state.extra as Customer;
        return TransactionHistoryPage(customer: customer);
      },
    ),
    GoRoute(
      path: '/agency_employees',
      builder: (context, state) => const AgencyEmployeesPage(),
    ),
  ],
);
