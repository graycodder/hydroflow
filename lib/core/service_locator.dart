import 'package:get_it/get_it.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydroflow/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:hydroflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:hydroflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:hydroflow/features/stock/data/repositories/inventory_repository_impl.dart';
import 'package:hydroflow/features/stock/domain/repositories/inventory_repository.dart';
import 'package:hydroflow/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:hydroflow/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:hydroflow/features/customers/domain/repositories/customer_repository.dart';
import 'package:hydroflow/features/bottles/presentation/bloc/bottle_bloc.dart';
import 'package:hydroflow/features/bottles/domain/usecases/get_bottle_ledger_usecase.dart';
import 'package:hydroflow/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:hydroflow/features/customers/domain/usecases/add_customer_usecase.dart';
import 'package:hydroflow/features/customers/domain/usecases/update_customer_status_usecase.dart';
import 'package:hydroflow/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:hydroflow/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:hydroflow/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:hydroflow/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:hydroflow/features/transactions/domain/usecases/get_today_transactions_usecase.dart';
import 'package:hydroflow/features/transactions/presentation/bloc/delivery_bloc.dart';
import 'package:hydroflow/features/reports/data/repositories/report_repository_impl.dart';
import 'package:hydroflow/features/reports/domain/repositories/report_repository.dart';
import 'package:hydroflow/features/reports/domain/usecases/get_daily_report_usecase.dart';
import 'package:hydroflow/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:hydroflow/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:hydroflow/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:hydroflow/features/subscription/domain/usecases/get_plans_usecase.dart';
import 'package:hydroflow/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:hydroflow/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:hydroflow/features/profile/domain/repositories/profile_repository.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:hydroflow/features/profile/domain/usecases/get_subscription_history_usecase.dart';
import 'package:hydroflow/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:hydroflow/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:hydroflow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:hydroflow/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:hydroflow/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:hydroflow/features/notifications/domain/usecases/mark_all_read_usecase.dart';
import 'package:hydroflow/features/notifications/presentation/bloc/notification_bloc.dart';


final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton<FirebaseDatabase>(() => FirebaseDatabase.instance);

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(database: sl(), sharedPreferences: sl()),
  );
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(database: sl()),
  );
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(database: sl()),
  );

  // Subscription
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(database: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetBottleLedgerUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));

  sl.registerLazySingleton(() => AddCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetPlansUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => StockBloc(inventoryRepository: sl()));
  sl.registerFactory(() => BottleBloc(getBottleLedger: sl()));
  sl.registerFactory(
    () => CustomerBloc(
      getCustomers: sl(),
      addCustomer: sl(),
      updateCustomerStatus: sl(),
    ),
  );

  // Transaction Feature
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(database: sl()),
  );
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTodayTransactionsUseCase(sl()));
  // Reports Feature
  sl.registerFactory(() => ReportsBloc(getDailyReportUseCase: sl()));
  sl.registerLazySingleton(() => GetDailyReportUseCase(sl()));
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(
      database: sl(),
      transactionRepository: sl(),
      customerRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => DeliveryBloc(
      addTransactionUseCase: sl(),
      getTodayTransactionsUseCase: sl(),
      customerRepository: sl(),
    ),
  );
  sl.registerFactory(() => SubscriptionBloc(getPlans: sl()));

  // Profile Feature
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(database: sl()),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetSubscriptionHistoryUseCase(sl()));
  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl(),
      getSubscriptionHistory: sl(),
    ),
  );

  // Notifications Feature
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(database: sl()),
  );
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => MarkNotificationReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllReadUseCase(sl()));
  sl.registerFactory(
    () => NotificationBloc(
      getNotifications: sl(),
      markRead: sl(),
      markAllRead: sl(),
    ),
  );
}
