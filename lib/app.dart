import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/core/theme/app_theme.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/blocs/reports/reports_cubit.dart';
import 'package:hisobnoma/presentation/blocs/settings/settings_cubit.dart';
import 'package:hisobnoma/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:hisobnoma/presentation/blocs/shift/shift_cubit.dart';
import 'package:hisobnoma/presentation/blocs/sync/sync_cubit.dart';
import 'package:hisobnoma/data/services/sync_service.dart';

/// Root application widget
class HisobnomaApp extends StatefulWidget {
  const HisobnomaApp({super.key});

  @override
  State<HisobnomaApp> createState() => _HisobnomaAppState();
}

class _HisobnomaAppState extends State<HisobnomaApp> with WidgetsBindingObserver {
  late final AuthCubit _authCubit;
  late final GoRouter _router;
  late final SyncService _syncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authCubit = getIt<AuthCubit>()..checkAuth();
    _router = createAppRouter(_authCubit);

    // Initialize sync service and trigger first sync
    _syncService = getIt<SyncService>()..initialize();
    _syncService.syncAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncService.syncAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncService.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider(create: (_) => getIt<DashboardCubit>()),
        BlocProvider(create: (_) => getIt<TransactionsCubit>()),
        BlocProvider(create: (_) => getIt<ReportsCubit>()),
        BlocProvider(create: (_) => getIt<SettingsCubit>()..loadSettings()),
        BlocProvider(create: (_) => getIt<AlertsCubit>()),
        BlocProvider(create: (_) => getIt<ShiftCubit>()),
        BlocProvider(create: (_) => getIt<SyncCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'Hisobnoma',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsState.themeMode,
            locale: settingsState.locale,
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
