import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/screens/auth/login_screen.dart';
import 'package:hisobnoma/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:hisobnoma/presentation/screens/transactions/transactions_screen.dart';
import 'package:hisobnoma/presentation/screens/reports/reports_screen.dart';
import 'package:hisobnoma/presentation/screens/settings/settings_screen.dart';
import 'package:hisobnoma/presentation/screens/alerts/alerts_screen.dart';
import 'package:hisobnoma/presentation/screens/finance/expense_screen.dart';
import 'package:hisobnoma/presentation/screens/finance/debtor_payment_screen.dart';
import 'package:hisobnoma/presentation/screens/finance/salary_payment_screen.dart';
import 'package:hisobnoma/presentation/screens/shell_screen.dart';
import 'package:hisobnoma/presentation/screens/splash/splash_screen.dart';

/// Route paths
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/';
  static const String transactions = '/transactions';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String alerts = '/alerts';
  static const String expenses = '/finance/expenses';
  static const String debtorPayments = '/finance/debtor-payments';
  static const String salaryPayments = '/finance/salary-payments';
}

/// Creates the app router with auth-aware redirect.
///
/// Listens to [AuthCubit] state changes to automatically redirect
/// between login and authenticated routes.
GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefreshNotifier(authCubit),
    redirect: (context, state) async {
      final authState = authCubit.state;
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      final isOnLogin = state.matchedLocation == AppRoutes.login;
      final isAuthenticated = authState is AuthAuthenticated;

      // While initial auth check is loading, stay on splash
      if (authState is AuthInitial) {
        return isOnSplash ? null : AppRoutes.splash;
      }

      // Login-related states — stay on / go to login
      if (authState is AuthUsersLoaded ||
          authState is AuthAccountSelected ||
          authState is AuthLoading) {
        return isOnLogin ? null : AppRoutes.login;
      }

      // Auth error — go to login
      if (authState is AuthError) {
        return isOnLogin ? null : AppRoutes.login;
      }

      // Auth resolved — leave splash
      if (isOnSplash) {
        return isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      // Authenticated user on login page → go home
      if (isAuthenticated && isOnLogin) {
        return AppRoutes.home;
      }

      // Unauthenticated user on protected page → go to login
      if (!isAuthenticated && !isOnLogin) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      // Splash (shown while auth resolves)
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

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
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TransactionsScreen()),
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
        path: AppRoutes.alerts,
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenses,
        builder: (context, state) => const ExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.debtorPayments,
        builder: (context, state) => const DebtorPaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.salaryPayments,
        builder: (context, state) => const SalaryPaymentScreen(),
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
