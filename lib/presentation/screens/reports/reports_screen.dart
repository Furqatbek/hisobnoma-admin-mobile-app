import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';

/// Reports screen with charts and breakdowns
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.reports, style: AppTypography.headline),
      ),
      body: const Center(
        child: Text('Reports — Coming in Block 8'),
      ),
    );
  }
}
