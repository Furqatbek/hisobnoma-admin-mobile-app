import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';

/// Login screen with username + PIN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _pinFocusNode = FocusNode();
  bool _obscurePin = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _pinController.dispose();
    _usernameFocusNode.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // App icon
                  FadeScaleIn(
                    child: _buildAppIcon(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeScaleIn(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      AppStrings.appName,
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
                      'Financial tracking made simple',
                      style: AppTypography.subheadline.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Login form
                  FadeScaleIn(
                    delay: const Duration(milliseconds: 300),
                    child: _buildLoginForm(context, isDark),
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

  Widget _buildLoginForm(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Username field
        Text(
          'Username',
          style: AppTypography.subheadline.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkFill : AppColors.fill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          child: TextField(
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _pinFocusNode.requestFocus(),
            style: AppTypography.body.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter username',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // PIN field
        Text(
          'PIN',
          style: AppTypography.subheadline.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkFill : AppColors.fill,
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          child: TextField(
            controller: _pinController,
            focusNode: _pinFocusNode,
            keyboardType: TextInputType.number,
            obscureText: _obscurePin,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onLogin(context),
            style: AppTypography.body.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              letterSpacing: _obscurePin ? 4 : 0,
            ),
            decoration: InputDecoration(
              hintText: 'Enter PIN',
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Error message
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthError) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  state.message,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Login button
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _onLogin(context),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Login'),
              ),
            );
          },
        ),
      ],
    );
  }

  void _onLogin(BuildContext context) {
    final username = _usernameController.text.trim();
    final pin = _pinController.text.trim();

    if (username.isEmpty) {
      _showError(context, 'Please enter your username');
      return;
    }
    if (pin.isEmpty) {
      _showError(context, 'Please enter your PIN');
      return;
    }

    HapticFeedback.mediumImpact();
    context.read<AuthCubit>().login(username: username, pin: pin);
  }

  void _showError(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
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
