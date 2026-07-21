import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _preferences;

  static const _themeKey = 'theme_mode';
  static const _currencyKey = 'currency';
  static const _localeKey = 'locale';

  static const supportedLocales = [Locale('en'), Locale('uz'), Locale('ru')];

  SettingsCubit({required SharedPreferences preferences})
    : _preferences = preferences,
      super(const SettingsState());

  void loadSettings() {
    final themeModeIndex = _preferences.getInt(_themeKey) ?? 0;
    final currency = _preferences.getString(_currencyKey) ?? 'UZS';
    final localeCode = _preferences.getString(_localeKey);

    Locale locale;
    if (localeCode != null) {
      locale = Locale(localeCode);
    } else {
      // Auto-detect from system and persist it
      locale = _resolveSystemLocale();
      _preferences.setString(_localeKey, locale.languageCode);
    }

    emit(
      SettingsState(
        themeMode: ThemeMode.values[themeModeIndex],
        currency: currency,
        locale: locale,
      ),
    );
  }

  Locale _resolveSystemLocale() {
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    final code = systemLocale.languageCode;
    if (code == 'uz') return const Locale('uz');
    if (code == 'ru') return const Locale('ru');
    return const Locale('en');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _preferences.setInt(_themeKey, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setCurrency(String currency) async {
    await _preferences.setString(_currencyKey, currency);
    emit(state.copyWith(currency: currency));
  }

  Future<void> setLocale(Locale locale) async {
    await _preferences.setString(_localeKey, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }
}
