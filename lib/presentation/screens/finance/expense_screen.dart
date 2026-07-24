import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/utils/money.dart';
import 'package:hisobnoma/data/models/finance/finance_models.dart';
import 'package:hisobnoma/data/repositories/finance_repository.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/screens/finance/finance_form_widgets.dart';
import 'package:hisobnoma/presentation/widgets/common/error_handler.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';

/// Record a business expense (cash or bank outflow).
class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = getIt<FinanceRepository>();

  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  DateTime _date = DateTime.now();
  PaymentSource _source = PaymentSource.cash;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await _repo.createExpense(
        amount: parseMoney(_amount.text),
        description: _description.text.trim(),
        expenseDate: formatDateYmd(_date),
        paymentSource: _source,
        category: _category.text.trim(),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      final t = S.of(context);
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      showSuccessSnackBar(context, t.expenseRecorded);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.recordExpense, style: AppTypography.headline),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            AmountField(controller: _amount),
            const SizedBox(height: AppSpacing.md),
            HisobTextField(
              label: t.description,
              controller: _description,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.fieldRequired : null,
            ),
            const SizedBox(height: AppSpacing.md),
            HisobTextField(
              label: t.category,
              controller: _category,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            DateField(
              label: t.date,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: AppSpacing.md),
            ChoiceRow<PaymentSource>(
              label: t.paymentSource,
              value: _source,
              options: [
                ChoiceOption(PaymentSource.cash, t.cash),
                ChoiceOption(PaymentSource.bank, t.bank),
              ],
              onChanged: (v) => setState(() => _source = v),
            ),
            const SizedBox(height: AppSpacing.md),
            HisobTextField(
              label: t.notes,
              controller: _notes,
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: t.save,
              submitting: _submitting,
              onPressed: _submit,
              color: AppColors.expense,
            ),
          ],
        ),
      ),
    );
  }
}
