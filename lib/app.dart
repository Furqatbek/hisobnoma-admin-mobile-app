import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/network/interceptors/auth_interceptor.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/core/services/push_notification_service.dart';
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

class _HisobnomaAppState extends State<HisobnomaApp>
    with WidgetsBindingObserver {
  late final AuthCubit _authCubit;
  late final GoRouter _router;
  late final SyncService _syncService;
  late final PushNotificationService _pushService;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authCubit = getIt<AuthCubit>();
    _router = createAppRouter(_authCubit);

    // Route to login when the server rejects our refresh token, so an expired
    // session never strands the user on silently-failing screens.
    getIt<AuthInterceptor>().onTokenExpired = _authCubit.handleSessionExpired;

    // Push notifications: register this device's token once authenticated,
    // unregister on logout. Attached before checkAuth so the login emitted by
    // checkAuth is caught. No-op on non-iOS until Android/FCM lands.
    _pushService = getIt<PushNotificationService>();
    _pushService.onNotificationTap = _handleNotificationTap;
    _authSub = _authCubit.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _pushService.enable();
      } else if (state is AuthUnauthenticated) {
        _pushService.disable();
      }
    });

    _initApp();

    _syncService = getIt<SyncService>();
    try {
      _syncService.initialize();
    } catch (_) {}
    _safeSyncAll();
  }

  Future<void> _initApp() async {
    try {
      await _authCubit.checkAuth();
    } catch (_) {}
    // Remove splash after auth resolves (regardless of success/failure)
    if (!kIsWeb) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {}
    }
  }

  Future<void> _safeSyncAll() async {
    try {
      await _syncService.syncAll();
    } catch (_) {}
  }

  /// Route when the user taps a notification. Minimal for now: honor an
  /// explicit `route` in the payload, else open Alerts. Richer per-type routing
  /// arrives with the Phase 4 payload contract.
  void _handleNotificationTap(Map<String, dynamic> data) {
    final route = data['route'] as String?;
    _router.go(route ?? AppRoutes.alerts);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _safeSyncAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
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
