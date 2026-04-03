part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String currency;
  final Locale? locale;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.currency = 'UZS',
    this.locale,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? currency,
    Locale? locale,
    bool clearLocale = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
      locale: clearLocale ? null : (locale ?? this.locale),
    );
  }

  @override
  List<Object?> get props => [themeMode, currency, locale];
}
