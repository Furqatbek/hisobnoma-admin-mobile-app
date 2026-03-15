import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/alert/alert_models.dart';
import 'package:hisobnoma/data/repositories/alert_repository.dart';

part 'alerts_state.dart';

class AlertsCubit extends Cubit<AlertsState> {
  final AlertRepository _alertRepository;

  AlertsCubit({required AlertRepository alertRepository})
      : _alertRepository = alertRepository,
        super(const AlertsInitial());

  Future<void> loadAlerts({bool unreadOnly = false, int page = 0}) async {
    emit(const AlertsLoading());
    try {
      final data = await _alertRepository.getAlerts(
        unreadOnly: unreadOnly,
        page: page,
      );
      emit(AlertsLoaded(
        alerts: data.content,
        page: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasMore,
      ));
    } catch (e) {
      emit(AlertsError(message: e.toString()));
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _alertRepository.getUnreadCount();
      final current = state;
      if (current is AlertsLoaded) {
        emit(current.copyWith(unreadCount: count));
      } else {
        emit(AlertsUnreadCountLoaded(count: count));
      }
    } catch (_) {
      // Silently fail for badge count
    }
  }

  Future<void> markAsRead(int alertId) async {
    try {
      await _alertRepository.markAsRead(alertId);
      final current = state;
      if (current is AlertsLoaded) {
        final updated = current.alerts
            .map((a) => a.id == alertId ? a.copyWith(isRead: true) : a)
            .toList();
        emit(current.copyWith(
          alerts: updated,
          unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
        ));
      }
    } catch (e) {
      emit(AlertsError(message: e.toString()));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _alertRepository.markAllAsRead();
      final current = state;
      if (current is AlertsLoaded) {
        final updated =
            current.alerts.map((a) => a.copyWith(isRead: true)).toList();
        emit(current.copyWith(alerts: updated, unreadCount: 0));
      }
    } catch (e) {
      emit(AlertsError(message: e.toString()));
    }
  }
}
