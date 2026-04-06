import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/shift/shift_cubit.dart';
import 'package:hisobnoma/presentation/widgets/common/error_handler.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';

class ShiftSheet extends StatefulWidget {
  const ShiftSheet({super.key});

  static Future<Shift?> show(BuildContext context) {
    return showModalBottomSheet<Shift>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ShiftCubit>(),
        child: const ShiftSheet(),
      ),
    );
  }

  @override
  State<ShiftSheet> createState() => _ShiftSheetState();
}

enum _CashOpType { none, cashIn, cashOut }

class _ShiftSheetState extends State<ShiftSheet> {
  // Open shift form
  final _openingCashController = TextEditingController();
  final _openNotesController = TextEditingController();
  List<PosTerminal> _terminals = [];
  PosTerminal? _selectedTerminal;
  bool _terminalsLoading = true;

  // Current shift (kept locally so we don't rely on bloc state for display)
  Shift? _currentShift;

  // Cash operation form
  _CashOpType _cashOpType = _CashOpType.none;
  final _cashOpAmountController = TextEditingController();
  final _cashOpReasonController = TextEditingController();

  // Close shift form
  final _closingCashController = TextEditingController();
  final _closingNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTerminals();
    context.read<ShiftCubit>().loadCurrentShift();
  }

  Future<void> _loadTerminals() async {
    final repo = context.read<ShiftCubit>().transactionRepository;
    try {
      final terminals = await repo.getActiveTerminals();
      if (!mounted) return;
      setState(() {
        _terminals = terminals;
        if (terminals.isNotEmpty) {
          _selectedTerminal = terminals.first;
        }
        _terminalsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _terminalsLoading = false);
      showErrorSnackBar(context, e);
    }
  }

  @override
  void dispose() {
    _openingCashController.dispose();
    _openNotesController.dispose();
    _cashOpAmountController.dispose();
    _cashOpReasonController.dispose();
    _closingCashController.dispose();
    _closingNotesController.dispose();
    super.dispose();
  }

  void _onOpenShift() {
    if (_selectedTerminal == null) return;
    final openingCash =
        double.tryParse(_openingCashController.text.trim()) ?? 0.0;
    HapticFeedback.mediumImpact();
    context.read<ShiftCubit>().openShift(
          terminalId: _selectedTerminal!.id,
          openingCash: openingCash,
          notes: _openNotesController.text.trim().isEmpty
              ? null
              : _openNotesController.text.trim(),
        );
  }

  void _onCloseShift() {
    if (_currentShift == null) return;
    final closingCash =
        double.tryParse(_closingCashController.text.trim()) ?? 0.0;
    HapticFeedback.mediumImpact();
    context.read<ShiftCubit>().closeShift(
          shiftId: _currentShift!.id,
          closingCash: closingCash,
          closingNotes: _closingNotesController.text.trim().isEmpty
              ? null
              : _closingNotesController.text.trim(),
        );
  }

  void _onCashOperation() {
    if (_currentShift == null || _cashOpType == _CashOpType.none) return;
    final amount =
        double.tryParse(_cashOpAmountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;
    HapticFeedback.mediumImpact();
    context.read<ShiftCubit>().cashOperation(
          shiftId: _currentShift!.id,
          operationType:
              _cashOpType == _CashOpType.cashIn ? 'CASH_IN' : 'CASH_OUT',
          amount: amount,
          reason: _cashOpReasonController.text.trim().isEmpty
              ? null
              : _cashOpReasonController.text.trim(),
        );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocListener<ShiftCubit, ShiftState>(
      listener: (context, state) {
        if (state is ShiftOpened) {
          _showSuccessSnackBar(S.of(context).shiftOpened);
          Navigator.of(context).pop(state.shift);
        } else if (state is ShiftClosed) {
          _showSuccessSnackBar(S.of(context).shiftClosed);
          Navigator.of(context).pop();
        } else if (state is ShiftError) {
          showErrorSnackBar(context, Exception(state.message));
          // Reload to restore the previous state
          context.read<ShiftCubit>().loadCurrentShift();
        } else if (state is ShiftLoaded) {
          setState(() {
            _currentShift = state.shift;
            if (state.shift.isOpen) {
              _closingCashController.text =
                  (state.shift.expectedCash ?? 0.0).toStringAsFixed(2);
            }
            // Reset cash operation form
            _cashOpType = _CashOpType.none;
            _cashOpAmountController.clear();
            _cashOpReasonController.clear();
          });
        } else if (state is ShiftNone) {
          setState(() => _currentShift = null);
        }
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            children: [
              _buildHandle(isDark),
              _buildHeader(isDark),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<ShiftCubit, ShiftState>(
                  builder: (context, state) {
                    if (state is ShiftLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (state is ShiftNone || _currentShift == null) {
                      return _buildNoShiftContent(isDark);
                    }
                    if (_currentShift != null && _currentShift!.isOpen) {
                      return _buildOpenShiftContent(isDark);
                    }
                    return _buildNoShiftContent(isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        width: 36,
        height: 5,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSeparator : AppColors.separator,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final t = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              t.shiftManagement,
              style: AppTypography.title3.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color:
                  isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── No Shift Open ──────────────────────────────────────────────────

  Widget _buildNoShiftContent(bool isDark) {
    final t = S.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Icon(
            Icons.point_of_sale_outlined,
            size: 56,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            t.noOpenShift,
            style: AppTypography.title3.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.noOpenShiftHint,
            style: AppTypography.subheadline.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Terminal selector
          Text(
            'Terminal',
            style: AppTypography.footnote.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildTerminalDropdown(isDark),
          const SizedBox(height: AppSpacing.md),

          // Opening cash
          HisobTextField(
            label: t.openingCash,
            hint: '0.00',
            controller: _openingCashController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Notes
          HisobTextField(
            label: t.notes,
            hint: '',
            controller: _openNotesController,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Open shift button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed:
                  _selectedTerminal != null ? _onOpenShift : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.royalBlue,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                disabledBackgroundColor:
                    isDark ? AppColors.darkFill : AppColors.fill,
              ),
              child: Text(
                t.openShift,
                style: AppTypography.headline.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildTerminalDropdown(bool isDark) {
    if (_terminalsLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkFill : AppColors.fill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_terminals.isEmpty) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkFill : AppColors.fill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(
          'No terminals available',
          style: AppTypography.body.copyWith(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkFill : AppColors.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PosTerminal>(
          value: _selectedTerminal,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          dropdownColor: isDark ? AppColors.darkCard : AppColors.white,
          style: AppTypography.body.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          items: _terminals.map((terminal) {
            return DropdownMenuItem<PosTerminal>(
              value: terminal,
              child: Text(
                '${terminal.name} (${terminal.terminalCode})',
                style: AppTypography.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: (terminal) {
            setState(() => _selectedTerminal = terminal);
          },
        ),
      ),
    );
  }

  // ─── Open Shift Content ─────────────────────────────────────────────

  Widget _buildOpenShiftContent(bool isDark) {
    final t = S.of(context);
    final shift = _currentShift!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shift info card
          _buildShiftInfoCard(isDark, shift),
          const SizedBox(height: AppSpacing.md),

          // Stats row
          _buildStatsRow(isDark, shift),
          const SizedBox(height: AppSpacing.md),

          // Cash operations
          _buildCashOperationSection(isDark, shift),
          const SizedBox(height: AppSpacing.lg),

          // Close shift section
          _buildCloseShiftSection(isDark, shift),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildShiftInfoCard(bool isDark, Shift shift) {
    final t = S.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkSeparator : AppColors.separator,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 18,
                color: AppColors.royalBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                t.currentShift,
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _infoRow(
            isDark,
            t.shiftNumber,
            shift.shiftNumber,
          ),
          const SizedBox(height: AppSpacing.sm),
          _infoRow(
            isDark,
            'Terminal',
            shift.terminalName,
          ),
          const SizedBox(height: AppSpacing.sm),
          _infoRow(
            isDark,
            t.cashier,
            shift.cashierName,
          ),
          const SizedBox(height: AppSpacing.sm),
          _infoRow(
            isDark,
            t.openedAt,
            '${Formatters.date(shift.openedAt)} ${Formatters.time(shift.openedAt)}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _infoRow(
            isDark,
            t.openingCash,
            Formatters.currency(shift.openingCash),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(bool isDark, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.footnote.copyWith(
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.footnote.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark, Shift shift) {
    final t = S.of(context);
    return Row(
      children: [
        Expanded(
          child: _statCard(
            isDark,
            t.totalSales,
            Formatters.currency(shift.totalSales),
            AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statCard(
            isDark,
            t.transactionsCount,
            shift.transactionCount.toString(),
            AppColors.royalBlue,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    bool isDark,
    String label,
    String value,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.darkSeparator : AppColors.separator,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption2.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashOperationSection(bool isDark, Shift shift) {
    final t = S.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkSeparator : AppColors.separator,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.cashOperation,
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _cashOpButton(
                  isDark,
                  t.cashIn,
                  Icons.add_circle_outline,
                  AppColors.income,
                  _CashOpType.cashIn,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _cashOpButton(
                  isDark,
                  t.cashOut,
                  Icons.remove_circle_outline,
                  AppColors.expense,
                  _CashOpType.cashOut,
                ),
              ),
            ],
          ),
          if (_cashOpType != _CashOpType.none) ...[
            const SizedBox(height: AppSpacing.md),
            HisobTextField(
              label: t.amount,
              hint: '0.00',
              controller: _cashOpAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            HisobTextField(
              label: t.reason,
              hint: '',
              controller: _cashOpReasonController,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _cashOpType = _CashOpType.none;
                      _cashOpAmountController.clear();
                      _cashOpReasonController.clear();
                    });
                  },
                  child: Text(
                    t.cancel,
                    style: AppTypography.subheadline.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _onCashOperation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cashOpType == _CashOpType.cashIn
                        ? AppColors.income
                        : AppColors.expense,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  child: Text(
                    t.confirm,
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cashOpButton(
    bool isDark,
    String label,
    IconData icon,
    Color color,
    _CashOpType type,
  ) {
    final isSelected = _cashOpType == type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _cashOpType = isSelected ? _CashOpType.none : type;
          _cashOpAmountController.clear();
          _cashOpReasonController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark ? AppColors.darkFill : AppColors.fill),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.subheadline.copyWith(
                color: isSelected
                    ? color
                    : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseShiftSection(bool isDark, Shift shift) {
    final t = S.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(
          color: isDark ? AppColors.darkSeparator : AppColors.separator,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.closeShift,
            style: AppTypography.headline.copyWith(
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Expected cash info
          _infoRow(
            isDark,
            t.expectedCash,
            Formatters.currency(shift.expectedCash ?? 0.0),
          ),
          const SizedBox(height: AppSpacing.md),

          // Closing cash field
          HisobTextField(
            label: t.closingCash,
            hint: '0.00',
            controller: _closingCashController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Closing notes
          HisobTextField(
            label: t.notes,
            hint: '',
            controller: _closingNotesController,
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),

          // Close shift button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _onCloseShift,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: Text(
                t.closeShift,
                style: AppTypography.headline.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
