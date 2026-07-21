part of 'sync_cubit.dart';

enum SyncUIStatus { idle, syncing, offline, completed, error }

class SyncState extends Equatable {
  final SyncUIStatus status;
  final DateTime? lastSyncAt;
  final int lastSyncCount;
  final String? errorMessage;
  final SyncInfo? syncInfo;

  const SyncState({
    this.status = SyncUIStatus.idle,
    this.lastSyncAt,
    this.lastSyncCount = 0,
    this.errorMessage,
    this.syncInfo,
  });

  SyncState copyWith({
    SyncUIStatus? status,
    DateTime? lastSyncAt,
    int? lastSyncCount,
    String? errorMessage,
    SyncInfo? syncInfo,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncCount: lastSyncCount ?? this.lastSyncCount,
      errorMessage: errorMessage ?? this.errorMessage,
      syncInfo: syncInfo ?? this.syncInfo,
    );
  }

  @override
  List<Object?> get props => [
    status,
    lastSyncAt,
    lastSyncCount,
    errorMessage,
    syncInfo,
  ];
}
