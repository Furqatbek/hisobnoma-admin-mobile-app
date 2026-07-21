import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/data/models/auth/user_account.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';

/// Login screen: select account → enter PIN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    if (state is AuthUnauthenticated || state is AuthInitial) {
      context.read<AuthCubit>().loadUsers();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  FadeScaleIn(child: _buildAppIcon()),
                  const SizedBox(height: AppSpacing.lg),
                  FadeScaleIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      t.appName,
                      style: AppTypography.title1.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeScaleIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      t.financialTrackingTagline,
                      style: AppTypography.subheadline.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Auth content
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (state is AuthUsersLoaded) {
                        return _buildAccountList(state.users, isDark);
                      }
                      if (state is AuthAccountSelected) {
                        return _buildPinEntry(state.selectedUser, isDark);
                      }
                      if (state is AuthError) {
                        if (state.selectedUser != null) {
                          return _buildPinEntry(
                            state.selectedUser!,
                            isDark,
                            errorMessage: state.message,
                          );
                        }
                        if (state.users != null && state.users!.isNotEmpty) {
                          return _buildAccountList(
                            state.users!,
                            isDark,
                            errorMessage: state.message,
                          );
                        }
                        return _buildErrorRetry(state.message, isDark);
                      }
                      if (state is AuthLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      // AuthInitial / AuthUnauthenticated — loading users
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountList(
    List<UserAccount> users,
    bool isDark, {
    String? errorMessage,
  }) {
    final t = S.of(context);
    return FadeScaleIn(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.selectAccount,
            style: AppTypography.title3.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (errorMessage != null) ...[
            Text(
              errorMessage,
              style: AppTypography.footnote.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ...users.map((user) => _buildAccountTile(user, isDark)),
        ],
      ),
    );
  }

  Widget _buildAccountTile(UserAccount user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: isDark ? AppColors.darkFill : AppColors.fill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          onTap: () {
            HapticFeedback.lightImpact();
            _pinController.clear();
            context.read<AuthCubit>().selectAccount(user);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Avatar with initials
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.royalBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: AppTypography.headline.copyWith(
                        color: AppColors.royalBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: AppTypography.body.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.username,
                        style: AppTypography.caption1.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinEntry(UserAccount user, bool isDark, {String? errorMessage}) {
    final t = S.of(context);
    return FadeScaleIn(
      child: Column(
        children: [
          // Back + selected user
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<AuthCubit>().backToAccountSelection();
                },
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: AppTypography.subheadline.copyWith(
                      color: AppColors.royalBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: AppTypography.headline.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user.username,
                      style: AppTypography.caption1.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // PIN field
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkFill : AppColors.fill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
            child: TextField(
              controller: _pinController,
              focusNode: _pinFocusNode,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onLogin(context, user),
              style: AppTypography.body.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                letterSpacing: _obscurePin ? 4 : 0,
              ),
              decoration: InputDecoration(
                hintText: t.enterPin,
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 0,
                ),
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin ? Icons.visibility_off : Icons.visibility,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Error message
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                errorMessage,
                style: AppTypography.footnote.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),

          // Login button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _onLogin(context, user),
              child: Text(t.login),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRetry(String message, bool isDark) {
    final t = S.of(context);
    return FadeScaleIn(
      child: Column(
        children: [
          Text(
            message,
            style: AppTypography.subheadline.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context.read<AuthCubit>().loadUsers(),
            child: Text(t.retry),
          ),
        ],
      ),
    );
  }

  void _onLogin(BuildContext context, UserAccount user) {
    final t = S.of(context);
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.pleaseEnterPin),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    context.read<AuthCubit>().login(username: user.username, pin: pin);
  }

  Widget _buildAppIcon() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.royalBlue,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'H',
          style: AppTypography.largeTitle.copyWith(
            color: AppColors.white,
            fontSize: 44,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
