import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/core/services/push_notification_service.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
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
    final t = S.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings, style: AppTypography.headline)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // -- Appearance --
              _SectionHeader(title: t.appearance),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  _ThemeTile(state: state, isDark: isDark),
                  HisobListTile(
                    title: t.language,
                    showChevron: true,
                    showDivider: false,
                    trailing: Text(
                      _languageLabel(state.locale),
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () => _showLanguagePicker(context, state.locale),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Notifications --
              _SectionHeader(title: t.notifications),
              _SettingsGroup(
                isDark: isDark,
                children: const [_NotificationsTile()],
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Finance --
              _SectionHeader(title: t.finance),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  HisobListTile(
                    title: t.recordExpense,
                    leading: Icon(
                      Icons.receipt_long_outlined,
                      size: 22,
                      color: AppColors.royalBlue,
                    ),
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.expenses),
                  ),
                  HisobListTile(
                    title: t.receivePayment,
                    leading: Icon(
                      Icons.payments_outlined,
                      size: 22,
                      color: AppColors.royalBlue,
                    ),
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.debtorPayments),
                  ),
                  HisobListTile(
                    title: t.salaryAdvances,
                    leading: Icon(
                      Icons.badge_outlined,
                      size: 22,
                      color: AppColors.royalBlue,
                    ),
                    showChevron: true,
                    showDivider: false,
                    onTap: () => context.push(AppRoutes.salaryPayments),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Data --
              _SectionHeader(title: t.data),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  HisobListTile(
                    title: t.syncData,
                    leading: Icon(
                      Icons.sync,
                      size: 22,
                      color: AppColors.royalBlue,
                    ),
                    showChevron: true,
                    showDivider: false,
                    onTap: () => _showSyncInfo(context, isDark),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // -- Account --
              _SectionHeader(title: t.account),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  HisobListTile.destructive(
                    title: t.logout,
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
                  t.appVersion,
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

  String _languageLabel(Locale? locale) {
    if (locale == null) return 'System';
    switch (locale.languageCode) {
      case 'uz':
        return 'Ўзбекча';
      case 'ru':
        return 'Русский';
      default:
        return 'English';
    }
  }

  void _showLanguagePicker(BuildContext context, Locale? currentLocale) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguagePickerSheet(
        selectedLocale: currentLocale,
        onSelected: (locale) {
          context.read<SettingsCubit>().setLocale(locale);
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

  void _confirmLogout(BuildContext context) {
    HapticFeedback.selectionClick();
    final t = S.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.logout),
        content: Text(t.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.of(dialogContext).pop();
              context.read<AuthCubit>().logout();
            },
            child: Text(t.logout, style: TextStyle(color: AppColors.error)),
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

/// Master push-notification toggle. Reflects the user's intent; enabling
/// triggers the iOS permission prompt (first time) and registers the device
/// token, disabling removes it so the backend stops sending.
class _NotificationsTile extends StatefulWidget {
  const _NotificationsTile();

  @override
  State<_NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends State<_NotificationsTile> {
  late final PushNotificationService _push = getIt<PushNotificationService>();
  late bool _enabled = _push.enabledPreference;

  Future<void> _onChanged(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _enabled = value);
    await _push.setEnabledPreference(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 22,
            color: AppColors.royalBlue,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.pushNotifications,
                  style: AppTypography.body.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.pushNotificationsDesc,
                  style: AppTypography.caption2.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(value: _enabled, onChanged: _onChanged),
        ],
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
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
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
    final t = S.of(context);
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
                  t.darkMode,
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
                  label: t.themeSystem,
                  isSelected: state.themeMode == ThemeMode.system,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<SettingsCubit>().setThemeMode(
                      ThemeMode.system,
                    );
                  },
                ),
                _ThemeOption(
                  label: t.themeLight,
                  isSelected: state.themeMode == ThemeMode.light,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<SettingsCubit>().setThemeMode(ThemeMode.light);
                  },
                ),
                _ThemeOption(
                  label: t.themeDark,
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

/// Language picker bottom sheet.
class _LanguagePickerSheet extends StatelessWidget {
  final Locale? selectedLocale;
  final ValueChanged<Locale> onSelected;

  const _LanguagePickerSheet({
    required this.selectedLocale,
    required this.onSelected,
  });

  static const _languages = [
    ('en', 'English', 'EN'),
    ('uz', 'Ўзбекча', 'УЗ'),
    ('ru', 'Русский', 'РУ'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        // Transparent Material so the ListTile rows below paint ink/background
        // on it rather than being hidden by this decorated Container.
        child: Material(
          type: MaterialType.transparency,
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
                child: Text(t.selectLanguage, style: AppTypography.headline),
              ),
              const Divider(height: 1),
              ..._languages.map((lang) {
                final code = lang.$1;
                final label = lang.$2;
                final badge = lang.$3;
                final isSelected = selectedLocale?.languageCode == code;
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.royalBlue.withValues(alpha: 0.1)
                          : (isDark ? AppColors.darkFill : AppColors.fill),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Text(
                        badge,
                        style: AppTypography.headline.copyWith(
                          color: isSelected
                              ? AppColors.royalBlue
                              : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.royalBlue)
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(Locale(code));
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
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
    final t = S.of(context);
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
                        : Icon(
                            Icons.sync,
                            size: 48,
                            color: AppColors.royalBlue,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    t.dataSync,
                    style: AppTypography.title3.copyWith(
                      color: widget.isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.syncDescription,
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
                    label: t.products,
                    count: info?.productCount,
                    lastSync: info?.productsLastSync,
                    isDark: widget.isDark,
                  ),
                  _SyncItem(
                    icon: Icons.people_outline,
                    label: t.customers,
                    count: info?.customerCount,
                    lastSync: info?.customersLastSync,
                    isDark: widget.isDark,
                  ),
                  _SyncItem(
                    icon: Icons.category_outlined,
                    label: t.categories,
                    count: info?.categoryCount,
                    lastSync: info?.categoriesLastSync,
                    isDark: widget.isDark,
                  ),
                  if (info != null && info.pendingActions > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        t.pendingOfflineActions('${info.pendingActions}'),
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
                      label: Text(isSyncing ? t.syncing : t.syncNow),
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
    final t = S.of(context);
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
                    t.itemsSynced('$count'),
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
