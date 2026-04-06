part of 'shift_cubit.dart';

abstract class ShiftState extends Equatable {
  const ShiftState();

  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {
  const ShiftInitial();
}

class ShiftLoading extends ShiftState {
  const ShiftLoading();
}

/// No open shift found
class ShiftNone extends ShiftState {
  const ShiftNone();
}

/// Current shift loaded
class ShiftLoaded extends ShiftState {
  final Shift shift;

  const ShiftLoaded({required this.shift});

  @override
  List<Object?> get props => [shift];
}

/// Shift just opened
class ShiftOpened extends ShiftState {
  final Shift shift;

  const ShiftOpened({required this.shift});

  @override
  List<Object?> get props => [shift];
}

/// Shift just closed
class ShiftClosed extends ShiftState {
  final Shift shift;

  const ShiftClosed({required this.shift});

  @override
  List<Object?> get props => [shift];
}

class ShiftError extends ShiftState {
  final String message;

  const ShiftError({required this.message});

  @override
  List<Object?> get props => [message];
}
