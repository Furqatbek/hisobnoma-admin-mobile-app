import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';

/// Shell screen with bottom navigation bar
class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.transactions:
        return 1;
      case AppRoutes.reports:
        return 2;
      case AppRoutes.settings:
        return 3;
      default:
        return 0;
    }
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.transactions);
      case 2:
        context.go(AppRoutes.reports);
      case 3:
        context.go(AppRoutes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: t.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: t.transactions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: t.reports,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: t.settings,
          ),
        ],
      ),
    );
  }
}
