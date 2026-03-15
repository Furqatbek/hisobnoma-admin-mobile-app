import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/network/interceptors/auth_interceptor.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/screens/auth/login_screen.dart';
import 'package:hisobnoma/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:hisobnoma/presentation/screens/transactions/transactions_screen.dart';
import 'package:hisobnoma/presentation/screens/reports/reports_screen.dart';
import 'package:hisobnoma/presentation/screens/settings/settings_screen.dart';
import 'package:hisobnoma/presentation/screens/alerts/alerts_screen.dart';
import 'package:hisobnoma/presentation/screens/shell_screen.dart';

/// Route paths
abstract final class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String transactions = '/transactions';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String alerts = '/alerts';
}

/// Creates the app router with auth-aware redirect.
///
/// Listens to [AuthCubit] state changes to automatically redirect
/// between login and authenticated routes.
GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthRefreshNotifier(authCubit),
    redirect: (context, state) async {
      final authInterceptor = getIt<AuthInterceptor>();
      final hasToken = await authInterceptor.hasToken();
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // If the user just authenticated, go home
      if (authCubit.state is AuthAuthenticated && isLoginRoute) {
        return AppRoutes.home;
      }

      // If logged out or no token, go to login
      if (!hasToken && !isLoginRoute) {
        return AppRoutes.login;
      }
      if (hasToken && isLoginRoute) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Login (outside shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReportsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: AppRoutes.alerts,
        builder: (context, state) => const AlertsScreen(),
      ),
    ],
  );
}

/// Converts [AuthCubit] stream into a [ChangeNotifier] for GoRouter's
/// refreshListenable.
class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthRefreshNotifier(AuthCubit authCubit) {
    _subscription = authCubit.stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
