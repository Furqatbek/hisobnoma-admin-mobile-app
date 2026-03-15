import 'package:flutter/material.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';

/// Transactions list screen with segmented filter
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.transactions, style: AppTypography.headline),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Open search
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Transactions — Coming in Block 7'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Open add transaction bottom sheet
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
