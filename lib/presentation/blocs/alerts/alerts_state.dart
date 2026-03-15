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
  final Map<String, dynamic> data;
  final int unreadCount;

  const AlertsLoaded({required this.data, this.unreadCount = 0});

  AlertsLoaded copyWith({Map<String, dynamic>? data, int? unreadCount}) {
    return AlertsLoaded(
      data: data ?? this.data,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [data, unreadCount];
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
