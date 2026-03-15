part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String currency;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.currency = 'UZS',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? currency,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [themeMode, currency];
}
