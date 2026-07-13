import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/utils/error_message.dart';
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
      emit(ShiftError(message: extractErrorMessage(e)));
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
      emit(ShiftError(message: extractErrorMessage(e)));
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
      // ShiftOpened is the transient "just opened" signal the sheet uses to
      // pop with a success message; ShiftLoaded is the canonical resting state
      // every other consumer (sale sheet, AppBar) checks. Emit both so the
      // next sale is not wrongly told there is no open shift.
      emit(ShiftOpened(shift: shift));
      emit(ShiftLoaded(shift: shift));
    } catch (_) {
      // Shift may have been opened but response parsing failed — check
      final current = await _transactionRepository.getCurrentShift();
      if (current != null && current.isOpen) {
        emit(ShiftOpened(shift: current));
        emit(ShiftLoaded(shift: current));
      } else {
        await loadCurrentShift();
      }
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
    } catch (_) {
      // The close POST failed or its response could not be parsed. Verify
      // with the server before claiming success — only emit ShiftClosed when
      // the backend confirms a closed shift, so a network failure is never
      // reported to the cashier as a successful close.
      final current = await _transactionRepository.getCurrentShift();
      if (current != null && current.isClosed) {
        emit(ShiftClosed(shift: current));
      } else {
        await loadCurrentShift();
      }
    }
  }

  /// Cash in/out operation — doesn't emit loading to keep UI stable
  Future<void> cashOperation({
    required int shiftId,
    required String operationType,
    required double amount,
    String? reason,
  }) async {
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
      emit(ShiftError(message: extractErrorMessage(e)));
    }
  }
}
