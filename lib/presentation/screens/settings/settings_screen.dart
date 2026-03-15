import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/blocs/settings/settings_cubit.dart';
import 'package:hisobnoma/presentation/blocs/sync/sync_cubit.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_list_tile.dart';

/// Settings screen with grouped Apple-style sections.
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
              // -- Appearance --
              _SectionHeader(title: AppStrings.appearance),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  _ThemeTile(state: state, isDark: isDark),
                  HisobListTile(
                    title: AppStrings.currency,
                    showChevron: true,
                    showDivider: false,
                    trailing: Text(
                      state.currency,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => _showCurrencyPicker(context, state.currency),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Data --
              _SectionHeader(title: AppStrings.data),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  HisobListTile(
                    title: AppStrings.syncData,
                    leading: Icon(
                      Icons.sync,
                      size: 22,
                      color: AppColors.royalBlue,
                    ),
                    showChevron: true,
                    onTap: () => _showSyncInfo(context, isDark),
                  ),
                  HisobListTile(
                    title: AppStrings.clearCache,
                    leading: Icon(
                      Icons.delete_sweep_outlined,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                    showChevron: true,
                    showDivider: false,
                    onTap: () => _confirmClearCache(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Notifications --
              _SectionHeader(title: AppStrings.notifications),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  HisobListTile(
                    title: AppStrings.alertPreferences,
                    leading: Icon(
                      Icons.notifications_outlined,
                      size: 22,
                      color: AppColors.warning,
                    ),
                    showChevron: true,
                    onTap: () {
                      HapticFeedback.selectionClick();
                    },
                  ),
                  HisobListTile(
                    title: AppStrings.devices,
                    leading: Icon(
                      Icons.devices_outlined,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                    showChevron: true,
                    showDivider: false,
                    onTap: () {
                      HapticFeedback.selectionClick();
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Account --
              _SectionHeader(title: AppStrings.account),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  HisobListTile.destructive(
                    title: AppStrings.logout,
                    leading: Icon(
                      Icons.logout,
                      size: 22,
                      color: AppColors.error,
                    ),
                    showDivider: false,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // App version
              Center(
                child: Text(
                  'Hisobnoma v1.0.0',
                  style: AppTypography.caption1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, String currentCurrency) {
    HapticFeedback.selectionClick();
    final currencies = ['UZS', 'USD', 'EUR', 'RUB'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CurrencyPickerSheet(
        currencies: currencies,
        selected: currentCurrency,
        onSelected: (currency) {
          context.read<SettingsCubit>().setCurrency(currency);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSyncInfo(BuildContext context, bool isDark) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SyncInfoSheet(isDark: isDark),
    );
  }

  void _confirmClearCache(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove cached data. You may need to sync again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cache cleared'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop();
              context.read<AuthCubit>().logout();
            },
            child: Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption1.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsGroup({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Theme mode tile with 3-way toggle: System / Light / Dark
class _ThemeTile extends StatelessWidget {
  final SettingsState state;
  final bool isDark;

  const _ThemeTile({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 22,
                color: AppColors.royalBlue,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  AppStrings.darkMode,
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkFill : AppColors.fill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: [
                _ThemeOption(
                  label: 'System',
                  isSelected: state.themeMode == ThemeMode.system,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context
                        .read<SettingsCubit>()
                        .setThemeMode(ThemeMode.system);
                  },
                ),
                _ThemeOption(
                  label: 'Light',
                  isSelected: state.themeMode == ThemeMode.light,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context
                        .read<SettingsCubit>()
                        .setThemeMode(ThemeMode.light);
                  },
                ),
                _ThemeOption(
                  label: 'Dark',
                  isSelected: state.themeMode == ThemeMode.dark,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<SettingsCubit>().setThemeMode(ThemeMode.dark);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Divider(
            height: 0.5,
            color: isDark ? AppColors.darkSeparator : AppColors.separator,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkElevated : AppColors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.subheadline.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary)
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Currency picker bottom sheet.
class _CurrencyPickerSheet extends StatelessWidget {
  final List<String> currencies;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selected,
    required this.onSelected,
  });

  static const _currencyNames = {
    'UZS': "Uzbekistani So'm",
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'RUB': 'Russian Ruble',
  };

  static const _currencySymbols = {
    'UZS': "so'm",
    'USD': '\$',
    'EUR': '\u20AC',
    'RUB': '\u20BD',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSeparator
                      : AppColors.separator,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Select Currency', style: AppTypography.headline),
            ),
            const Divider(height: 1),
            ...currencies.map((code) {
              final isSelected = code == selected;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.royalBlue.withValues(alpha: 0.1)
                        : (isDark ? AppColors.darkFill : AppColors.fill),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      _currencySymbols[code] ?? code,
                      style: AppTypography.headline.copyWith(
                        color: isSelected
                            ? AppColors.royalBlue
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  code,
                  style: AppTypography.body.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  _currencyNames[code] ?? code,
                  style: AppTypography.caption1.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: AppColors.royalBlue)
                    : null,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(code);
                },
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// Sync info bottom sheet.
class _SyncInfoSheet extends StatefulWidget {
  final bool isDark;

  const _SyncInfoSheet({required this.isDark});

  @override
  State<_SyncInfoSheet> createState() => _SyncInfoSheetState();
}

class _SyncInfoSheetState extends State<_SyncInfoSheet> {
  @override
  void initState() {
    super.initState();
    context.read<SyncCubit>().loadSyncInfo();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        final info = state.syncInfo;
        final isSyncing = state.status == SyncUIStatus.syncing;

        return Container(
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkElevated : AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? AppColors.darkSeparator
                          : AppColors.separator,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isSyncing
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator.adaptive(),
                          )
                        : Icon(Icons.sync, size: 48,
                            color: AppColors.royalBlue),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Data Sync',
                    style: AppTypography.title3.copyWith(
                      color: widget.isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sync products, customers, and categories from the server for offline use.',
                    style: AppTypography.subheadline.copyWith(
                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SyncItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    count: info?.productCount,
                    lastSync: info?.productsLastSync,
                    isDark: widget.isDark,
                  ),
                  _SyncItem(
                    icon: Icons.people_outline,
                    label: 'Customers',
                    count: info?.customerCount,
                    lastSync: info?.customersLastSync,
                    isDark: widget.isDark,
                  ),
                  _SyncItem(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    count: info?.categoryCount,
                    lastSync: info?.categoriesLastSync,
                    isDark: widget.isDark,
                  ),
                  if (info != null && info.pendingActions > 0)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        '${info.pendingActions} pending offline action(s)',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSyncing
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              context.read<SyncCubit>().syncAll();
                            },
                      icon: const Icon(Icons.sync, size: 18),
                      label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SyncItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final DateTime? lastSync;
  final bool isDark;

  const _SyncItem({
    required this.icon,
    required this.label,
    this.count,
    this.lastSync,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                if (count != null)
                  Text(
                    '$count items synced',
                    style: AppTypography.caption2.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            lastSync != null
                ? Icons.check_circle_outline
                : Icons.circle_outlined,
            size: 18,
            color: lastSync != null ? AppColors.income : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
