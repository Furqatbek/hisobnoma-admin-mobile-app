import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/core/utils/formatters.dart';
import 'package:hisobnoma/core/utils/money.dart';
import 'package:hisobnoma/data/models/transaction/transaction_models.dart';
import 'package:hisobnoma/data/repositories/transaction_repository.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/widgets/common/error_handler.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';

/// Bottom sheet to change a product's persistent selling/wholesale price.
/// Returns `true` from [show] when the price was updated.
class PriceEditSheet extends StatefulWidget {
  final InventoryProduct product;

  const PriceEditSheet({super.key, required this.product});

  static Future<bool?> show(BuildContext context, InventoryProduct product) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PriceEditSheet(product: product),
      ),
    );
  }

  @override
  State<PriceEditSheet> createState() => _PriceEditSheetState();
}

class _PriceEditSheetState extends State<PriceEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _repo = getIt<TransactionRepository>();

  late final _selling = TextEditingController(
    text: formatQuantity(widget.product.sellingPrice),
  );
  final _wholesale = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _selling.dispose();
    _wholesale.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final wholesale = parseMoney(_wholesale.text);
      await _repo.updateProductPrice(
        productId: widget.product.id,
        sellingPrice: parseMoney(_selling.text),
        wholesalePrice: wholesale > 0 ? wholesale : null,
      );
      if (!mounted) return;
      final t = S.of(context);
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
      showSuccessSnackBar(context, t.priceUpdated);
    } catch (e) {
      // Surfaces the backend message, incl. PRICE_BELOW_MIN.
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = S.of(context);
    final p = widget.product;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSeparator
                            : AppColors.separator,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    t.editPrice,
                    style: AppTypography.title3.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.name,
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (p.minSellingPrice > 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${t.minPrice}: ${Formatters.currency(p.minSellingPrice)}',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  HisobTextField(
                    label: t.sellingPrice,
                    controller: _selling,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return t.fieldRequired;
                      if (parseMoney(v) <= 0) return t.fieldRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HisobTextField(
                    label: t.wholesalePrice,
                    controller: _wholesale,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(t.save),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
