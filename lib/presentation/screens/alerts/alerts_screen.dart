import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';

/// Alerts list screen
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.alerts, style: AppTypography.headline),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mark all as read
            },
            child: const Text(AppStrings.markAllRead),
          ),
        ],
      ),
      body: const Center(
        child: Text('Alerts — Coming in Block 10'),
      ),
    );
  }
}
