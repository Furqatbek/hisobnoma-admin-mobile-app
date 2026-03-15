import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_strings.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/utils/phone_formatter.dart';
import 'package:hisobnoma/presentation/blocs/auth/auth_cubit.dart';
import 'package:hisobnoma/presentation/widgets/common/animations.dart';
import 'package:hisobnoma/presentation/widgets/common/hisob_otp_field.dart';

/// Login screen with two steps: phone entry → OTP verification
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpKey = GlobalKey<_OtpSectionState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
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
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
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

                // Auth form (switches between phone and OTP)
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthCodeSent) {
                      return _OtpSection(
                        key: _otpKey,
                        phone: state.phone,
                      );
                    }
                    if (state is AuthError && state.phone != null) {
                      return _OtpSection(
                        key: _otpKey,
                        phone: state.phone!,
                        errorMessage: state.message,
                      );
                    }
                    return _PhoneSection(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                    );
                  },
                ),

                const Spacer(flex: 3),
              ],
            ),
          ),
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

/// Phone number input section
class _PhoneSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _PhoneSection({
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeScaleIn(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.phoneNumber,
            style: AppTypography.subheadline.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Phone input with country code prefix
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkFill : AppColors.fill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
            child: Row(
              children: [
                // Country code
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: isDark
                            ? AppColors.darkSeparator
                            : AppColors.separator,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    '+998',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                // Phone number
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.phone,
                    style: AppTypography.body.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '90 123 45 67',
                      hintStyle: AppTypography.body.copyWith(
                        color: AppColors.textTertiary,
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
                      LengthLimitingTextInputFormatter(9),
                      UzbekPhoneFormatter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Send code button
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onSendCode(context),
                  child: const Text(AppStrings.sendCode),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onSendCode(BuildContext context) {
    final digits = controller.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 9) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid 9-digit phone number'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final phone = cleanPhoneNumber(digits);
    context.read<AuthCubit>().sendCode(phone);
  }
}

/// OTP verification section
class _OtpSection extends StatefulWidget {
  final String phone;
  final String? errorMessage;

  const _OtpSection({
    super.key,
    required this.phone,
    this.errorMessage,
  });

  @override
  State<_OtpSection> createState() => _OtpSectionState();
}

class _OtpSectionState extends State<_OtpSection> {
  bool _hasError = false;

  @override
  void didUpdateWidget(_OtpSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != null && oldWidget.errorMessage == null) {
      setState(() => _hasError = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _hasError = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeScaleIn(
      child: Column(
        children: [
          // Back button + title
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<AuthCubit>().backToPhone();
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
              Expanded(
                child: Text(
                  AppStrings.verificationCode,
                  style: AppTypography.title3.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enter the 6-digit code sent to ${widget.phone}',
            style: AppTypography.subheadline.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // OTP input
          HisobOtpField(
            length: 6,
            hasError: _hasError,
            onCompleted: (code) {
              context.read<AuthCubit>().verifyCode(
                    phone: widget.phone,
                    code: code,
                  );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Loading indicator
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.md),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Error message
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                widget.errorMessage!,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Resend code
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<AuthCubit>().sendCode(widget.phone);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Code resent'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              );
            },
            child: Text(
              'Resend Code',
              style: AppTypography.subheadline.copyWith(
                color: AppColors.royalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
