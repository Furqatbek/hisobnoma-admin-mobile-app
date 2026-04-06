import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/blocs/transactions/transactions_cubit.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_text_field.dart';

/// A bottom sheet for selecting an existing client or creating a new one.
/// Returns the selected client as Map<String, dynamic> via Navigator.pop().
class ClientSelectionSheet extends StatefulWidget {
  const ClientSelectionSheet({super.key});

  /// Shows the sheet and returns selected client map, or null if cancelled.
  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionsCubit>(),
        child: const ClientSelectionSheet(),
      ),
    );
  }

  @override
  State<ClientSelectionSheet> createState() => _ClientSelectionSheetState();
}

class _ClientSelectionSheetState extends State<ClientSelectionSheet> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();

  bool _isCreateExpanded = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<TransactionsCubit>().searchCustomers(query);
  }

  void _onClientTapped(Map<String, dynamic> client) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(client);
  }

  void _toggleCreateForm() {
    HapticFeedback.selectionClick();
    setState(() {
      _isCreateExpanded = !_isCreateExpanded;
      if (_isCreateExpanded) {
        _nameController.clear();
        _phoneController.clear();
      }
    });
  }

  void _onCreateClient() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      HapticFeedback.heavyImpact();
      _nameFocus.requestFocus();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isCreating = true);

    final phone = _phoneController.text.trim();
    context.read<TransactionsCubit>().createCustomer(
          name: name,
          phone: phone.isEmpty ? null : phone,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return BlocListener<TransactionsCubit, TransactionsState>(
      listener: (context, state) {
        if (state is CustomerCreated) {
          HapticFeedback.heavyImpact();
          final t = S.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.clientCreated),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(state.customer);
        } else if (state is TransactionsError && _isCreating) {
          setState(() => _isCreating = false);
          final t = S.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.failedToCreateClient),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkElevated : AppColors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(isDark),
              _buildHeader(isDark),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: HisobTextField(
                  hint: S.of(context).searchClients,
                  controller: _searchController,
                  focusNode: _searchFocus,
                  autofocus: true,
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              _buildCreateSection(isDark),
              const Divider(height: 1),
              Flexible(
                child: _buildClientList(isDark),
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
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Text(
              t.cancel,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              t.selectClient,
              style: AppTypography.headline.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Invisible spacer to balance the cancel button
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _buildCreateSection(bool isDark) {
    final t = S.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggleCreateForm,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.royalBlue.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.royalBlue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      t.quickCreateClient,
                      style: AppTypography.callout.copyWith(
                        color: AppColors.royalBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isCreateExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.royalBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isCreateExpanded) _buildCreateForm(isDark),
        ],
      ),
    );
  }

  Widget _buildCreateForm(bool isDark) {
    final t = S.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkFill : AppColors.fill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HisobTextField(
              label: t.clientName,
              hint: t.name,
              controller: _nameController,
              focusNode: _nameFocus,
              prefixIcon: Icon(
                Icons.person_outline,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            HisobTextField(
              label: t.clientPhone,
              hint: t.phone,
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              prefixIcon: Icon(
                Icons.phone_outlined,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _onCreateClient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor:
                      AppColors.royalBlue.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        t.createNewClient,
                        style: AppTypography.callout.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(bool isDark) {
    return BlocBuilder<TransactionsCubit, TransactionsState>(
      buildWhen: (_, current) =>
          current is CustomersSearchLoaded ||
          current is TransactionsLoading ||
          current is TransactionsError,
      builder: (context, state) {
        if (state is TransactionsLoading) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.royalBlue,
              ),
            ),
          );
        }

        if (state is CustomersSearchLoaded) {
          final customers = state.customers;

          if (customers.isEmpty && state.query.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 48,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      S.of(context).noClientsFound,
                      style: AppTypography.subheadline.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            itemCount: customers.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: AppSpacing.md + 40 + AppSpacing.sm,
              color: isDark ? AppColors.darkSeparator : AppColors.separator,
            ),
            itemBuilder: (context, index) {
              final client = customers[index];
              return _buildClientTile(client, isDark);
            },
          );
        }

        // Initial state - show empty prompt
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Text(
              S.of(context).searchClients,
              style: AppTypography.footnote.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textTertiary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientTile(Map<String, dynamic> client, bool isDark) {
    final name = client['name'] as String? ?? '';
    final code = client['code'] as String? ?? '';
    final phone = client['phone'] as String?;

    final firstLetter =
        name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: () => _onClientTapped(client),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.royalBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                firstLetter,
                style: AppTypography.headline.copyWith(
                  color: AppColors.royalBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.callout.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone != null && phone.isNotEmpty
                        ? '$code  |  $phone'
                        : code,
                    style: AppTypography.caption1.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
