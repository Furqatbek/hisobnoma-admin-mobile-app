import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(AlertsLoaded(data: data));
    } catch (e) {
      emit(AlertsError(message: e.toString()));
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _alertRepository.getUnreadCount();
      emit(state is AlertsLoaded
          ? (state as AlertsLoaded).copyWith(unreadCount: count)
          : AlertsUnreadCountLoaded(count: count));
    } catch (_) {
      // Silently fail for badge count
    }
  }

  Future<void> markAsRead(int alertId) async {
    try {
      await _alertRepository.markAsRead(alertId);
      loadAlerts();
    } catch (e) {
      emit(AlertsError(message: e.toString()));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _alertRepository.markAllAsRead();
      loadAlerts();
    } catch (e) {
      emit(AlertsError(message: e.toString()));
    }
  }
}
