import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hisobnoma/core/constants/app_colors.dart';
import 'package:hisobnoma/core/constants/app_spacing.dart';
import 'package:hisobnoma/core/constants/app_typography.dart';
import 'package:hisobnoma/core/di/injection.dart';
import 'package:hisobnoma/data/models/telegram/telegram_models.dart';
import 'package:hisobnoma/data/repositories/telegram_repository.dart';
import 'package:hisobnoma/l10n/generated/app_localizations.dart';
import 'package:hisobnoma/presentation/widgets/common/error_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// Link (or unlink) the signed-in user's Telegram account.
///
/// Flow: tap "Link Telegram" → a 6-digit code is shown → open the bot in
/// Telegram and send the code → tap "I've sent it" to re-check status.
class TelegramLinkScreen extends StatefulWidget {
  const TelegramLinkScreen({super.key});

  @override
  State<TelegramLinkScreen> createState() => _TelegramLinkScreenState();
}

class _TelegramLinkScreenState extends State<TelegramLinkScreen> {
  final _repo = getIt<TelegramRepository>();

  TelegramStatus? _status;
  TelegramLinkCode? _code;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final status = await _repo.getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        // Once linked, the pending code is no longer relevant.
        if (status.linked) _code = null;
      });
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateCode() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final code = await _repo.generateLinkCode();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _code = code);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openTelegram() async {
    final bot = _code?.botUsername ?? _status?.botUsername ?? '';
    if (bot.isEmpty) return;
    final uri = Uri.parse('https://t.me/$bot');
    // externalApplication opens the Telegram app if installed, else browser.
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _unlink() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repo.unlink();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _code = null);
      await _loadStatus();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(t.telegram, style: AppTypography.headline)),
      body: _loading && _status == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                _StatusCard(status: _status, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),
                if (_status?.linked == true)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _unlink,
                      child: Text(t.unlinkTelegram),
                    ),
                  )
                else ...[
                  Text(
                    t.telegramLinkHint,
                    style: AppTypography.subheadline.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_code == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _generateCode,
                        child: Text(t.linkTelegram),
                      ),
                    )
                  else
                    _CodePanel(
                      code: _code!,
                      isDark: isDark,
                      busy: _busy || _loading,
                      onOpenTelegram: _openTelegram,
                      onCheck: _loadStatus,
                    ),
                ],
              ],
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final TelegramStatus? status;
  final bool isDark;

  const _StatusCard({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final linked = status?.linked == true;
    final color = linked ? AppColors.income : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            linked ? Icons.check_circle_outline : Icons.link_off,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linked ? t.telegramLinked : t.telegramNotLinked,
                  style: AppTypography.subheadline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                if ((status?.botUsername ?? '').isNotEmpty)
                  Text(
                    '@${status!.botUsername}',
                    style: AppTypography.caption1.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the 6-digit code with "Open Telegram" and a re-check action.
class _CodePanel extends StatelessWidget {
  final TelegramLinkCode code;
  final bool isDark;
  final bool busy;
  final VoidCallback onOpenTelegram;
  final VoidCallback onCheck;

  const _CodePanel({
    required this.code,
    required this.isDark,
    required this.busy,
    required this.onOpenTelegram,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${t.sendCodeToBot} @${code.botUsername}',
          style: AppTypography.subheadline.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code.code));
            HapticFeedback.selectionClick();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Text(
              code.code,
              textAlign: TextAlign.center,
              style: AppTypography.largeTitle.copyWith(
                letterSpacing: 8,
                color: AppColors.royalBlue,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          t.codeExpires,
          textAlign: TextAlign.center,
          style: AppTypography.caption1.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton.icon(
          onPressed: onOpenTelegram,
          icon: const Icon(Icons.send_outlined, size: 18),
          label: Text(t.openTelegram),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: busy ? null : onCheck,
          child: Text(t.checkLink),
        ),
      ],
    );
  }
}
