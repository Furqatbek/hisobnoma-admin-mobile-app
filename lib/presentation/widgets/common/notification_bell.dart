import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/router/app_router.dart';
import 'package:hisobnoma/presentation/blocs/alerts/alerts_cubit.dart';

/// App-bar notification bell with a live unread-count badge.
///
/// Reads the shared [AlertsCubit] (provided app-wide), so the badge stays in
/// sync with the Alerts center. Tapping opens the Alerts screen and refreshes
/// the unread count on return.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  int _unreadOf(AlertsState state) {
    if (state is AlertsLoaded) return state.unreadCount;
    if (state is AlertsUnreadCountLoaded) return state.count;
    return 0;
  }

  Future<void> _openAlerts(BuildContext context) async {
    await context.push(AppRoutes.alerts);
    // Refresh the badge after the user leaves the Alerts screen (they may have
    // marked items read there).
    if (context.mounted) {
      context.read<AlertsCubit>().loadUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertsCubit, AlertsState>(
      builder: (context, state) {
        final unread = _unreadOf(state);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              onPressed: () => _openAlerts(context),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: AppTypography.caption2.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
