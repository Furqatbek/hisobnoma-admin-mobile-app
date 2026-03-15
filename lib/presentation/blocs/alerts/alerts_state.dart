part of 'alerts_cubit.dart';

abstract class AlertsState extends Equatable {
  const AlertsState();

  @override
  List<Object?> get props => [];
}

class AlertsInitial extends AlertsState {
  const AlertsInitial();
}

class AlertsLoading extends AlertsState {
  const AlertsLoading();
}

class AlertsLoaded extends AlertsState {
  final List<Alert> alerts;
  final int unreadCount;
  final int page;
  final int totalPages;
  final bool hasMore;

  const AlertsLoaded({
    required this.alerts,
    this.unreadCount = 0,
    this.page = 0,
    this.totalPages = 0,
    this.hasMore = false,
  });

  AlertsLoaded copyWith({
    List<Alert>? alerts,
    int? unreadCount,
    int? page,
    int? totalPages,
    bool? hasMore,
  }) {
    return AlertsLoaded(
      alerts: alerts ?? this.alerts,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [alerts, unreadCount, page, totalPages, hasMore];
}

class AlertsUnreadCountLoaded extends AlertsState {
  final int count;

  const AlertsUnreadCountLoaded({required this.count});

  @override
  List<Object?> get props => [count];
}

class AlertsError extends AlertsState {
  final String message;

  const AlertsError({required this.message});

  @override
  List<Object?> get props => [message];
}
