import 'package:get_it/get_it.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watermemo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:watermemo/features/auth/domain/repositories/auth_repository.dart';
import 'package:watermemo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:watermemo/features/stock/data/repositories/inventory_repository_impl.dart';
import 'package:watermemo/features/stock/domain/repositories/inventory_repository.dart';
import 'package:watermemo/features/stock/presentation/bloc/stock_bloc.dart';
import 'package:watermemo/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:watermemo/features/customers/domain/repositories/customer_repository.dart';
import 'package:watermemo/features/bottles/presentation/bloc/bottle_bloc.dart';
import 'package:watermemo/features/bottles/domain/usecases/get_bottle_ledger_usecase.dart';
import 'package:watermemo/features/bottles/domain/usecases/get_salesman_bottle_ledger_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/add_customer_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/update_customer_status_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:watermemo/features/customers/domain/usecases/settle_customer_usecase.dart';
import 'package:watermemo/features/customers/presentation/bloc/customer_bloc.dart';
import 'package:watermemo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:watermemo/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:watermemo/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:watermemo/features/transactions/domain/usecases/get_today_transactions_usecase.dart';
import 'package:watermemo/features/transactions/domain/usecases/get_customer_transactions_usecase.dart';
import 'package:watermemo/features/transactions/presentation/bloc/delivery_bloc.dart';
import 'package:watermemo/features/transactions/presentation/bloc/customer_transactions_bloc.dart';
import 'package:watermemo/features/reports/data/repositories/report_repository_impl.dart';
import 'package:watermemo/features/reports/domain/repositories/report_repository.dart';
import 'package:watermemo/features/reports/domain/usecases/get_daily_report_usecase.dart';
import 'package:watermemo/features/reports/domain/usecases/get_monthly_report_usecase.dart';
import 'package:watermemo/features/reports/domain/usecases/get_agency_daily_report_usecase.dart';
import 'package:watermemo/features/reports/domain/usecases/get_agency_monthly_report_usecase.dart';
import 'package:watermemo/features/reports/domain/usecases/record_settlement_usecase.dart';
import 'package:watermemo/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:watermemo/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:watermemo/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:watermemo/features/subscription/domain/usecases/get_plans_usecase.dart';
import 'package:watermemo/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:watermemo/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:watermemo/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:watermemo/features/profile/domain/repositories/profile_repository.dart';
import 'package:watermemo/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:watermemo/features/profile/domain/usecases/get_subscription_history_usecase.dart';
import 'package:watermemo/features/profile/domain/usecases/get_agency_profile_usecase.dart';
import 'package:watermemo/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:watermemo/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:watermemo/features/notifications/domain/repositories/notification_repository.dart';
import 'package:watermemo/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:watermemo/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:watermemo/features/notifications/domain/usecases/mark_all_read_usecase.dart';
import 'package:watermemo/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:watermemo/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:watermemo/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:watermemo/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:watermemo/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:watermemo/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:watermemo/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:watermemo/core/bloc/connectivity/connectivity_bloc.dart';
import 'package:watermemo/features/auth/presentation/bloc/agency_bloc.dart';
import 'package:watermemo/features/auth/domain/repositories/agency_repository.dart';
import 'package:watermemo/features/auth/data/repositories/agency_repository_impl.dart';



final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  
  // Enable Firebase Disk Persistence
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10MB cache

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
  sl.registerLazySingleton(() => GetBottleLedgerUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetSalesmanBottleLedgerUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));

  sl.registerLazySingleton(() => AddCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerStatusUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => SettleCustomerUseCase(sl()));
  sl.registerLazySingleton(() => GetPlansUseCase(sl()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl(), agencyRepository: sl(), prefs: sl()));
  sl.registerFactory(() => StockBloc(
    inventoryRepository: sl(),
    customerRepository: sl(),
  ));
  sl.registerFactory(() => BottleBloc(getBottleLedger: sl()));
  sl.registerFactory(
    () => CustomerBloc(
      getCustomers: sl(),
      addCustomer: sl(),
      updateCustomerStatus: sl(),
      updateCustomer: sl(),
      settleCustomer: sl(),
      prefs: sl(),
    ),
  );

  // Transaction Feature
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(database: sl()),
  );
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTodayTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerTransactionsUseCase(sl()));
  // Reports Feature
  sl.registerFactory(
    () => ReportsBloc(
      getDailyReportUseCase: sl(),
      getMonthlyReportUseCase: sl(),
      getAgencyDailyReportUseCase: sl(),
      getAgencyMonthlyReportUseCase: sl(),
      recordSettlementUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetDailyReportUseCase(sl()));
  sl.registerLazySingleton(() => GetMonthlyReportUseCase(sl()));
  sl.registerLazySingleton(() => GetAgencyDailyReportUseCase(sl()));
  sl.registerLazySingleton(() => GetAgencyMonthlyReportUseCase(sl()));
  sl.registerLazySingleton(() => RecordSettlementUseCase(sl()));
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
      authRepository: sl(),
      agencyRepository: sl(),
      inventoryRepository: sl(),
      prefs: sl(),
    ),
  );
  sl.registerFactory(
    () => CustomerTransactionsBloc(
      getCustomerTransactionsUseCase: sl(),
    ),
  );
  sl.registerFactory(() => SubscriptionBloc(getPlans: sl()));

  // Profile Feature
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(database: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetSubscriptionHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetAgencyProfileUseCase(sl()));
  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl(),
      getSubscriptionHistory: sl(),
      getAgencyProfile: sl(),
      agencyRepository: sl(),
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

  // Dashboard Feature
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(database: sl(), reportRepository: sl()),
  );
  sl.registerLazySingleton(() => GetDashboardSummaryUseCase(sl()));
  sl.registerLazySingleton(() => ConnectivityBloc());
  sl.registerFactory(() => DashboardBloc(getDashboardSummary: sl()));
  // Agency Feature
  sl.registerLazySingleton<AgencyRepository>(
    () => AgencyRepositoryImpl(database: sl()),
  );
  sl.registerFactory(() => AgencyBloc(agencyRepository: sl()));
}

