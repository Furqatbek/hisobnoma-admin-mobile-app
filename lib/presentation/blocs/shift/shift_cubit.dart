import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';

part 'shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final TransactionRepository _transactionRepository;

  ShiftCubit({
    required TransactionRepository transactionRepository,
  })  : _transactionRepository = transactionRepository,
        super(const ShiftInitial());

  TransactionRepository get transactionRepository => _transactionRepository;

  /// Load current shift for the user
  Future<void> loadCurrentShift() async {
    emit(const ShiftLoading());
    try {
      final shift = await _transactionRepository.getCurrentShift();
      if (shift != null) {
        emit(ShiftLoaded(shift: shift));
      } else {
        emit(const ShiftNone());
      }
    } catch (e) {
      emit(ShiftError(message: e.toString()));
    }
  }

  /// Load current shift for a specific terminal
  Future<void> loadCurrentShiftForTerminal(int terminalId) async {
    emit(const ShiftLoading());
    try {
      final shift =
          await _transactionRepository.getCurrentShiftForTerminal(terminalId);
      if (shift != null) {
        emit(ShiftLoaded(shift: shift));
      } else {
        emit(const ShiftNone());
      }
    } catch (e) {
      emit(ShiftError(message: e.toString()));
    }
  }

  /// Open a new shift
  Future<void> openShift({
    required int terminalId,
    required double openingCash,
    String? notes,
  }) async {
    emit(const ShiftLoading());
    try {
      final shift = await _transactionRepository.openShift(
        terminalId: terminalId,
        openingCash: openingCash,
        notes: notes,
      );
      emit(ShiftOpened(shift: shift));
    } catch (e) {
      emit(ShiftError(message: e.toString()));
    }
  }

  /// Close the current shift
  Future<void> closeShift({
    required int shiftId,
    required double closingCash,
    String? closingNotes,
  }) async {
    emit(const ShiftLoading());
    try {
      final shift = await _transactionRepository.closeShift(
        shiftId: shiftId,
        closingCash: closingCash,
        closingNotes: closingNotes,
      );
      emit(ShiftClosed(shift: shift));
    } catch (e) {
      emit(ShiftError(message: e.toString()));
    }
  }

  /// Cash in/out operation
  Future<void> cashOperation({
    required int shiftId,
    required String operationType,
    required double amount,
    String? reason,
  }) async {
    emit(const ShiftLoading());
    try {
      await _transactionRepository.cashOperation(
        shiftId: shiftId,
        operationType: operationType,
        amount: amount,
        reason: reason,
      );
      // Reload shift to get updated totals
      await loadCurrentShift();
    } catch (e) {
      emit(ShiftError(message: e.toString()));
    }
  }
}
