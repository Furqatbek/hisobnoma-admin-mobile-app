import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/core/utils/money.dart';
import 'package:hisobnoma/data/models/finance/finance_models.dart';
import 'package:hisobnoma/data/repositories/finance_repository.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/screens/finance/finance_form_widgets.dart';
import 'package:hisobnoma/presentation/widgets/common/error_handler.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';

/// Record a payment received from a debtor (reduces their AR balance).
class DebtorPaymentScreen extends StatefulWidget {
  const DebtorPaymentScreen({super.key});

  @override
  State<DebtorPaymentScreen> createState() => _DebtorPaymentScreenState();
}

class _DebtorPaymentScreenState extends State<DebtorPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = getIt<FinanceRepository>();
  final _txRepo = getIt<TransactionRepository>();

  final _amount = TextEditingController();
  final _notes = TextEditingController();

  Map<String, dynamic>? _customer;
  ArPaymentMethod _method = ArPaymentMethod.cash;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerPickerSheet(loader: _txRepo.getFinanceCustomers),
    );
    if (selected != null) setState(() => _customer = selected);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final t = S.of(context);
    if (_customer == null) {
      showErrorSnackBar(context, t.selectCustomer);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await _repo.recordDebtorPayment(
        customerId: (_customer!['id'] as num).toInt(),
        amount: parseMoney(_amount.text),
        method: _method,
        notes: _notes.text.trim(),
      );
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

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final customerName = _customer?['name'] as String?;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.receivePayment, style: AppTypography.headline),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            PickerField(
              label: t.customer,
              selectedText: customerName,
              placeholder: t.selectCustomer,
              onTap: _pickCustomer,
            ),
            const SizedBox(height: AppSpacing.md),
            AmountField(controller: _amount),
            const SizedBox(height: AppSpacing.md),
            ChoiceRow<ArPaymentMethod>(
              label: t.paymentMethod,
              value: _method,
              options: [
                ChoiceOption(ArPaymentMethod.cash, t.cash),
                ChoiceOption(ArPaymentMethod.card, t.card),
                ChoiceOption(ArPaymentMethod.bank, t.bank),
              ],
              onChanged: (v) => setState(() => _method = v),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing finance customers with a live filter.
class _CustomerPickerSheet extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> Function() loader;

  const _CustomerPickerSheet({required this.loader});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
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
        _all = list;
        _filtered = list;
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

  void _filter(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((c) {
              final name = (c['name'] ?? '').toString().toLowerCase();
              final phone = (c['phone'] ?? '').toString().toLowerCase();
              return name.contains(query) || phone.contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
              child: HisobTextField(
                hint: t.selectCustomer,
                prefixIcon: const Icon(Icons.search, size: 20),
                onChanged: _filter,
              ),
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
      itemCount: _filtered.length,
      itemBuilder: (context, i) {
        final c = _filtered[i];
        final balance = (c['currentBalance'] as num?)?.toDouble();
        return ListTile(
          title: Text(
            (c['name'] ?? '').toString(),
            style: AppTypography.body.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          subtitle: balance != null ? Text(Formatters.currency(balance)) : null,
          onTap: () => Navigator.of(context).pop(c),
        );
      },
    );
  }
}
