import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/services/push_notification_service.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/alert/alert_models.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/alerts/alerts_cubit.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_empty_state.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_segmented_control.dart';
import 'package:hisobnoma/presentation/widgets/common/loading_shimmer.dart';

/// Alerts list screen with date grouping, swipe-to-read, and filtering.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _AlertFilter _filter = _AlertFilter.all;

  @override
  void initState() {
    super.initState();
    context.read<AlertsCubit>().loadAlerts();
    // Opening the Alerts center means the user has seen their notifications —
    // clear the app-icon badge.
    getIt<PushNotificationService>().clearBadge();
  }

  void _onFilterChanged(_AlertFilter filter) {
    HapticFeedback.selectionClick();
    setState(() => _filter = filter);
    context
        .read<AlertsCubit>()
        .loadAlerts(unreadOnly: filter == _AlertFilter.unread);
  }

  void _onMarkAllRead() {
    HapticFeedback.mediumImpact();
    context.read<AlertsCubit>().markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(t.alerts, style: AppTypography.headline),
        actions: [
          BlocBuilder<AlertsCubit, AlertsState>(
            builder: (context, state) {
              final hasUnread = state is AlertsLoaded && state.unreadCount > 0;
              return TextButton(
                onPressed: hasUnread ? _onMarkAllRead : null,
                child: Text(
                  t.markAllRead,
                  style: AppTypography.subheadline.copyWith(
                    color: hasUnread
                        ? AppColors.royalBlue
                        : AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            child: HisobSegmentedControl<_AlertFilter>(
              segments: [
                HisobSegment(value: _AlertFilter.all, label: t.all),
                HisobSegment(value: _AlertFilter.unread, label: t.unread),
              ],
              selectedValue: _filter,
              onChanged: _onFilterChanged,
            ),
          ),
          // Alert list
          Expanded(
            child: BlocBuilder<AlertsCubit, AlertsState>(
              builder: (context, state) {
                if (state is AlertsLoading) {
                  return const _AlertsShimmer();
                }
                if (state is AlertsError) {
                  return HisobEmptyState(
                    icon: Icons.error_outline,
                    title: t.error,
                    message: state.message,
                    actionLabel: t.retry,
                    onAction: () => context.read<AlertsCubit>().loadAlerts(
                          unreadOnly: _filter == _AlertFilter.unread,
                        ),
                  );
                }
                if (state is AlertsLoaded) {
                  if (state.alerts.isEmpty) {
                    return HisobEmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: t.noAlerts,
                      message: _filter == _AlertFilter.unread
                          ? t.allCaughtUp
                          : t.noAlertsToShow,
                    );
                  }
                  return _AlertList(
                    alerts: state.alerts,
                    hasMore: state.hasMore,
                    page: state.page,
                    filter: _filter,
                    isDark: isDark,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter enum
// ---------------------------------------------------------------------------

enum _AlertFilter { all, unread }

// ---------------------------------------------------------------------------
// Alert list with date grouping
// ---------------------------------------------------------------------------

class _AlertList extends StatelessWidget {
  final List<Alert> alerts;
  final bool hasMore;
  final int page;
  final _AlertFilter filter;
  final bool isDark;

  const _AlertList({
    required this.alerts,
    required this.hasMore,
    required this.page,
    required this.filter,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Group alerts by relative date
    final groups = <String, List<Alert>>{};
    for (final alert in alerts) {
      final key = Formatters.relativeDate(alert.createdAt);
      groups.putIfAbsent(key, () => []).add(alert);
    }

    final keys = groups.keys.toList();

    return RefreshIndicator(
      onRefresh: () => context
          .read<AlertsCubit>()
          .loadAlerts(unreadOnly: filter == _AlertFilter.unread),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          bottom: AppSpacing.xxl,
        ),
        itemCount: keys.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Load-more indicator
          if (index >= keys.length) {
            _loadMore(context);
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }

          final dateLabel = keys[index];
          final groupAlerts = groups[dateLabel]!;

          return StaggeredListItem(
            index: index,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(
                    dateLabel.toUpperCase(),
                    style: AppTypography.footnote.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Alert cards in group
                Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkCard : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (int i = 0; i < groupAlerts.length; i++)
                        _AlertTile(
                          alert: groupAlerts[i],
                          isDark: isDark,
                          showDivider: i < groupAlerts.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _loadMore(BuildContext context) {
    context.read<AlertsCubit>().loadAlerts(
          unreadOnly: filter == _AlertFilter.unread,
          page: page + 1,
        );
  }
}

// ---------------------------------------------------------------------------
// Single alert tile with swipe-to-mark-read
// ---------------------------------------------------------------------------

class _AlertTile extends StatelessWidget {
  final Alert alert;
  final bool isDark;
  final bool showDivider;

  const _AlertTile({
    required this.alert,
    required this.isDark,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(alert.id),
      direction:
          alert.isRead ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.royalBlue,
        child: const Icon(
          Icons.done_all,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        context.read<AlertsCubit>().markAsRead(alert.id);
        return false; // Don't remove from list, just mark read
      },
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (!alert.isRead) {
                context.read<AlertsCubit>().markAsRead(alert.id);
              }
              _showAlertDetail(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon with priority accent
                  _AlertIcon(
                    alertType: alert.alertType,
                    priority: alert.priority,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert.title,
                                style: AppTypography.subheadline.copyWith(
                                  fontWeight: alert.isRead
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              Formatters.time(alert.createdAt),
                              style: AppTypography.caption2.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alert.message,
                          style: AppTypography.footnote.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Unread dot
                  if (!alert.isRead) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.royalBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md + 36 + AppSpacing.md,
              ),
              child: Divider(
                height: 0.5,
                thickness: 0.5,
                color: isDark ? AppColors.darkSeparator : AppColors.separator,
              ),
            ),
        ],
      ),
    );
  }

  void _showAlertDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppColors.darkElevated : AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSeparator : AppColors.separator,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Icon + priority badge
            Row(
              children: [
                _AlertIcon(
                  alertType: alert.alertType,
                  priority: alert.priority,
                  size: 44,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: AppTypography.headline.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _PriorityBadge(priority: alert.priority),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _alertTypeLabel(context, alert.alertType),
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Message
            Text(
              alert.message,
              style: AppTypography.body.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Timestamp
            Text(
              '${Formatters.relativeDate(alert.createdAt)} at ${Formatters.time(alert.createdAt)}',
              style: AppTypography.footnote.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alert type icon with priority-colored background
// ---------------------------------------------------------------------------

class _AlertIcon extends StatelessWidget {
  final AlertType alertType;
  final AlertPriority priority;
  final double size;

  const _AlertIcon({
    required this.alertType,
    required this.priority,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        _alertTypeIcon(alertType),
        size: size * 0.5,
        color: color,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Priority badge
// ---------------------------------------------------------------------------

class _PriorityBadge extends StatelessWidget {
  final AlertPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _priorityLabel(context, priority),
        style: AppTypography.caption2.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeleton
// ---------------------------------------------------------------------------

class _AlertsShimmer extends StatelessWidget {
  const _AlertsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        const LoadingShimmer(height: 14, borderRadius: 4),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < 4; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                LoadingShimmer.circle(size: 36),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer.line(width: 200),
                      SizedBox(height: AppSpacing.xs),
                      LoadingShimmer.line(width: 280, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        const LoadingShimmer(height: 14, borderRadius: 4),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < 3; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                LoadingShimmer.circle(size: 36),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer.line(width: 180),
                      SizedBox(height: AppSpacing.xs),
                      LoadingShimmer.line(width: 250, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

IconData _alertTypeIcon(AlertType type) {
  return switch (type) {
    AlertType.lowStock => Icons.inventory_2_outlined,
    AlertType.outOfStock => Icons.remove_shopping_cart_outlined,
    AlertType.expiringInventory => Icons.timer_outlined,
    AlertType.largeTransaction => Icons.receipt_long_outlined,
    AlertType.dailySummary => Icons.summarize_outlined,
    AlertType.priceChange => Icons.trending_up,
    AlertType.newOrder => Icons.shopping_bag_outlined,
    AlertType.paymentReceived => Icons.account_balance_wallet_outlined,
    AlertType.paymentDue => Icons.schedule_outlined,
    AlertType.paymentOverdue => Icons.warning_amber_outlined,
    AlertType.system => Icons.settings_outlined,
  };
}

Color _priorityColor(AlertPriority priority) {
  return switch (priority) {
    AlertPriority.low => AppColors.textTertiary,
    AlertPriority.normal => AppColors.royalBlue,
    AlertPriority.high => AppColors.warning,
    AlertPriority.urgent => AppColors.error,
  };
}

String _priorityLabel(BuildContext context, AlertPriority priority) {
  final t = S.of(context);
  return switch (priority) {
    AlertPriority.low => t.priorityLow,
    AlertPriority.normal => t.priorityNormal,
    AlertPriority.high => t.priorityHigh,
    AlertPriority.urgent => t.priorityUrgent,
  };
}

String _alertTypeLabel(BuildContext context, AlertType type) {
  final t = S.of(context);
  return switch (type) {
    AlertType.lowStock => t.alertLowStock,
    AlertType.outOfStock => t.alertOutOfStock,
    AlertType.expiringInventory => t.alertExpiring,
    AlertType.largeTransaction => t.alertTransaction,
    AlertType.dailySummary => t.alertSummary,
    AlertType.priceChange => t.alertPriceChange,
    AlertType.newOrder => t.alertNewOrder,
    AlertType.paymentReceived => t.alertPayment,
    AlertType.paymentDue => t.alertPaymentDue,
    AlertType.paymentOverdue => t.alertOverdue,
    AlertType.system => t.alertSystem,
  };
}
