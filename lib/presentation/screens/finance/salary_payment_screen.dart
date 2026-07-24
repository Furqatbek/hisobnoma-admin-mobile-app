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

/// Record a salary (period-based) or an advance to an employee. Salary and
/// advance post to two different backend endpoints.
class SalaryPaymentScreen extends StatefulWidget {
  const SalaryPaymentScreen({super.key});

  @override
  State<SalaryPaymentScreen> createState() => _SalaryPaymentScreenState();
}

class _SalaryPaymentScreenState extends State<SalaryPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = getIt<FinanceRepository>();

  final _amount = TextEditingController();
  final _notes = TextEditingController();

  Employee? _employee;
  SalaryPaymentType _type = SalaryPaymentType.salary;
  // Period defaults to the current month; advance also carries its own date.
  int _periodYear = DateTime.now().year;
  int _periodMonth = DateTime.now().month;
  DateTime _advanceDate = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickEmployee() async {
    final selected = await showModalBottomSheet<Employee>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmployeePickerSheet(loader: _repo.getEmployees),
    );
    if (selected != null) setState(() => _employee = selected);
  }

  Future<void> _pickPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_periodYear, _periodMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: S.of(context).period,
    );
    if (picked != null) {
      setState(() {
        _periodYear = picked.year;
        _periodMonth = picked.month;
      });
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final t = S.of(context);
    if (_employee == null) {
      showErrorSnackBar(context, t.selectEmployee);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final amount = parseMoney(_amount.text);
      if (_type == SalaryPaymentType.salary) {
        await _repo.recordSalary(
          employeeId: _employee!.id,
          periodYear: _periodYear,
          periodMonth: _periodMonth,
          baseAmount: amount,
          notes: _notes.text.trim(),
        );
      } else {
        await _repo.recordAdvance(
          employeeId: _employee!.id,
          amount: amount,
          periodYear: _periodYear,
          periodMonth: _periodMonth,
          advanceDate: formatDateYmd(_advanceDate),
          notes: _notes.text.trim(),
        );
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      showSuccessSnackBar(context, t.paymentRecorded);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _periodText =>
      '$_periodYear-${_periodMonth.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final isAdvance = _type == SalaryPaymentType.advance;
    return Scaffold(
      appBar: AppBar(title: Text(t.paySalary, style: AppTypography.headline)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            PickerField(
              label: t.employee,
              selectedText: _employee?.name,
              placeholder: t.selectEmployee,
              onTap: _pickEmployee,
            ),
            const SizedBox(height: AppSpacing.md),
            ChoiceRow<SalaryPaymentType>(
              label: t.paymentType,
              value: _type,
              options: [
                ChoiceOption(SalaryPaymentType.salary, t.salary),
                ChoiceOption(SalaryPaymentType.advance, t.advance),
              ],
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: AppSpacing.md),
            AmountField(controller: _amount),
            const SizedBox(height: AppSpacing.md),
            PickerField(
              label: t.period,
              selectedText: _periodText,
              placeholder: _periodText,
              onTap: _pickPeriod,
            ),
            if (isAdvance) ...[
              const SizedBox(height: AppSpacing.md),
              DateField(
                label: t.date,
                value: _advanceDate,
                onChanged: (d) => setState(() => _advanceDate = d),
              ),
            ],
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing employees.
class _EmployeePickerSheet extends StatefulWidget {
  final Future<List<Employee>> Function() loader;

  const _EmployeePickerSheet({required this.loader});

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  List<Employee> _employees = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.loader();
      if (!mounted) return;
      setState(() {
        _employees = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = extractErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSeparator : AppColors.separator,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(t.selectEmployee, style: AppTypography.headline),
            ),
            Expanded(child: _body(scrollController, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _body(ScrollController controller, bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      controller: controller,
      itemCount: _employees.length,
      itemBuilder: (context, i) {
        final e = _employees[i];
        return ListTile(
          title: Text(
            e.name,
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          subtitle: e.position != null ? Text(e.position!) : null,
          onTap: () => Navigator.of(context).pop(e),
        );
      },
    );
  }
}
