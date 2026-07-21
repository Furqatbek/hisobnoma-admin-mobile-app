import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/services/sync_service.dart';

part 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncService _syncService;
  StreamSubscription<SyncStatus>? _statusSub;

  SyncCubit({required SyncService syncService})
    : _syncService = syncService,
      super(const SyncState()) {
    _statusSub = _syncService.statusStream.listen(_onStatusChanged);
  }

  void _onStatusChanged(SyncStatus status) {
    switch (status) {
      case SyncIdle():
        emit(state.copyWith(status: SyncUIStatus.idle));
      case SyncSyncing():
        emit(state.copyWith(status: SyncUIStatus.syncing));
      case SyncOffline():
        emit(state.copyWith(status: SyncUIStatus.offline));
      case SyncCompleted(:final syncedAt, :final itemCount):
        emit(
          state.copyWith(
            status: SyncUIStatus.completed,
            lastSyncAt: syncedAt,
            lastSyncCount: itemCount,
          ),
        );
      case SyncError(:final message):
        emit(state.copyWith(status: SyncUIStatus.error, errorMessage: message));
    }
  }

  /// Trigger a full sync
  Future<void> syncAll() async {
    await _syncService.syncAll();
  }

  /// Sync individual entities
  Future<void> syncProducts() async {
    emit(state.copyWith(status: SyncUIStatus.syncing));
    try {
      final count = await _syncService.syncProducts();
      emit(
        state.copyWith(
          status: SyncUIStatus.completed,
          lastSyncAt: DateTime.now(),
          lastSyncCount: count,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SyncUIStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> syncCustomers() async {
    emit(state.copyWith(status: SyncUIStatus.syncing));
    try {
      final count = await _syncService.syncCustomers();
      emit(
        state.copyWith(
          status: SyncUIStatus.completed,
          lastSyncAt: DateTime.now(),
          lastSyncCount: count,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SyncUIStatus.error, errorMessage: e.toString()),
      );
    }
  }

  Future<void> syncCategories() async {
    emit(state.copyWith(status: SyncUIStatus.syncing));
    try {
      final count = await _syncService.syncCategories();
      emit(
        state.copyWith(
          status: SyncUIStatus.completed,
          lastSyncAt: DateTime.now(),
          lastSyncCount: count,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SyncUIStatus.error, errorMessage: e.toString()),
      );
    }
  }

  /// Load sync info for display
  Future<void> loadSyncInfo() async {
    try {
      final info = await _syncService.getSyncInfo();
      emit(state.copyWith(syncInfo: info));
    } catch (_) {
      // Silently fail
    }
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    return super.close();
  }
}
