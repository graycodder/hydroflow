import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hydroflow/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:hydroflow/features/stock/presentation/pages/stock_page.dart';
import 'package:hydroflow/features/auth/presentation/pages/login_page.dart';
import 'package:hydroflow/features/bottles/presentation/pages/bottles_page.dart';
import 'package:hydroflow/features/customers/presentation/pages/customers_page.dart';
import 'package:hydroflow/features/transactions/presentation/pages/delivery_page.dart';
import 'package:hydroflow/features/reports/presentation/pages/reports_page.dart';
import 'package:hydroflow/features/splash/presentation/pages/splash_page.dart';
import 'package:hydroflow/features/notifications/presentation/pages/notifications_page.dart';
import 'package:hydroflow/features/profile/presentation/pages/subscription_lock_page.dart';
import 'package:hydroflow/features/profile/presentation/pages/profile_page.dart';
import 'package:hydroflow/features/auth/domain/entities/salesman.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/lock',
      builder: (context, state) {
        final salesman = state.extra as Salesman;
        return SubscriptionLockPage(salesman: salesman);
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
  ],
);
