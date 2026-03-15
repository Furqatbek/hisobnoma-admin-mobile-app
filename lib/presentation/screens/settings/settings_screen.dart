import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/presentation/blocs/settings/settings_cubit.dart';

/// Settings screen with grouped list items
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings, style: AppTypography.headline),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Appearance section
              Text(AppStrings.appearance,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.textSecondary,
                  )),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkCard : AppColors.cardBackground,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(AppStrings.darkMode,
                          style: AppTypography.body),
                      value: state.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        context.read<SettingsCubit>().setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                    ),
                    const Divider(indent: 16),
                    ListTile(
                      title: Text(AppStrings.currency,
                          style: AppTypography.body),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.currency,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              )),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textTertiary),
                        ],
                      ),
                      onTap: () {
                        // TODO: Open currency picker
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Account section
              Text(AppStrings.account,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.textSecondary,
                  )),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkCard : AppColors.cardBackground,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusCard),
                ),
                child: ListTile(
                  title: Text(
                    AppStrings.logout,
                    style: AppTypography.body.copyWith(color: AppColors.error),
                  ),
                  onTap: () {
                    // TODO: Confirm and logout
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // App version
              Center(
                child: Text(
                  'v1.0.0',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
