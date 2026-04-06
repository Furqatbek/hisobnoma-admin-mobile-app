import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisobnoma/core/config/app_config.dart';
import 'package:hisobnoma/core/network/api_client.dart';
import 'package:hisobnoma/core/network/connectivity_checker.dart';
import 'package:hisobnoma/core/network/interceptors/auth_interceptor.dart';
import 'package:hisobnoma/data/local/database_helper.dart';
import 'package:hisobnoma/data/repositories/auth_repository.dart';
import 'package:hisobnoma/data/repositories/dashboard_repository.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';
import 'package:hisobnoma/data/repositories/alert_repository.dart';
import 'package:hisobnoma/data/repositories/sync_repository.dart';
import 'package:hisobnoma/data/services/sync_service.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/blocs/reports/reports_cubit.dart';
import 'package:hisobnoma/presentation/blocs/settings/settings_cubit.dart';
import 'package:hisobnoma/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:hisobnoma/presentation/blocs/shift/shift_cubit.dart';
import 'package:hisobnoma/presentation/blocs/sync/sync_cubit.dart';

final getIt = GetIt.instance;

/// Initialize all dependencies
Future<void> configureDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);

  // Local Database
  final databaseHelper = DatabaseHelper();
  getIt.registerSingleton<DatabaseHelper>(databaseHelper);

  // Connectivity
  final connectivityChecker = ConnectivityChecker();
  getIt.registerSingleton<ConnectivityChecker>(connectivityChecker);

  // Network
  final authInterceptor = AuthInterceptor(secureStorage: secureStorage);
  getIt.registerSingleton<AuthInterceptor>(authInterceptor);

  final apiClient = ApiClient(
    baseUrl: AppConfig.current.baseUrl,
    authInterceptor: authInterceptor,
    enableLogging: AppConfig.current.enableLogging,
  );
  getIt.registerSingleton<ApiClient>(apiClient);

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient: getIt(), authInterceptor: getIt()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(apiClient: getIt()),
  );
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(apiClient: getIt()),
  );
  getIt.registerLazySingleton<AlertRepository>(
    () => AlertRepository(apiClient: getIt()),
  );
  getIt.registerLazySingleton<SyncRepository>(
    () => SyncRepository(apiClient: getIt()),
  );

  // Services
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      syncRepository: getIt(),
      apiClient: getIt(),
      databaseHelper: getIt(),
      connectivityChecker: getIt(),
    ),
  );

  // Blocs / Cubits
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(authRepository: getIt()),
  );
  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(dashboardRepository: getIt()),
  );
  getIt.registerFactory<TransactionsCubit>(
    () => TransactionsCubit(transactionRepository: getIt()),
  );
  getIt.registerFactory<ReportsCubit>(
    () => ReportsCubit(dashboardRepository: getIt()),
  );
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(preferences: getIt()),
  );
  getIt.registerFactory<AlertsCubit>(
    () => AlertsCubit(alertRepository: getIt()),
  );
  getIt.registerFactory<ShiftCubit>(
    () => ShiftCubit(transactionRepository: getIt()),
  );
  getIt.registerFactory<SyncCubit>(
    () => SyncCubit(syncService: getIt()),
  );
}
