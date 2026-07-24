import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/money.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';

/// Amount input with a numeric keyboard and a "> 0" validator.
class AmountField extends StatelessWidget {
  final TextEditingController controller;

  const AmountField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return HisobTextField(
      label: t.amount,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
      ],
      validator: (v) {
        if (v == null || v.trim().isEmpty) return t.fieldRequired;
        if (parseMoney(v) <= 0) return t.fieldRequired;
        return null;
      },
    );
  }
}

/// Read-only date field that opens a date picker.
class DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return HisobTextField(
      label: label,
      readOnly: true,
      controller: TextEditingController(text: formatDateYmd(value)),
      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(value.year + 1, 12, 31),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// A labelled option for [ChoiceRow].
class ChoiceOption<T> {
  final T value;
  final String label;
  const ChoiceOption(this.value, this.label);
}

/// A segmented single-choice row (e.g. Cash/Bank, Salary/Advance).
class ChoiceRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<ChoiceOption<T>> options;
  final ValueChanged<T> onChanged;

  const ChoiceRow({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.subheadline.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkFill : AppColors.fill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: options.map((o) {
              final selected = o.value == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(o.value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? AppColors.darkElevated : AppColors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        o.label,
                        style: AppTypography.subheadline.copyWith(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary)
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Full-width submit button with a busy spinner.
class SubmitButton extends StatelessWidget {
  final String label;
  final bool submitting;
  final VoidCallback onPressed;
  final Color? color;

  const SubmitButton({
    super.key,
    required this.label,
    required this.submitting,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: color != null
            ? ElevatedButton.styleFrom(backgroundColor: color)
            : null,
        onPressed: submitting ? null : onPressed,
        child: submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// A tappable field that shows the current selection and opens a picker sheet.
class PickerField extends StatelessWidget {
  final String label;
  final String? selectedText;
  final String placeholder;
  final VoidCallback onTap;

  const PickerField({
    super.key,
    required this.label,
    required this.selectedText,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HisobTextField(
      label: label,
      readOnly: true,
      controller: TextEditingController(text: selectedText ?? ''),
      hint: placeholder,
      suffixIcon: const Icon(Icons.expand_more, size: 20),
      onTap: onTap,
    );
  }
}
