import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _preferences;

  static const _themeKey = 'theme_mode';
  static const _currencyKey = 'currency';

  SettingsCubit({required SharedPreferences preferences})
      : _preferences = preferences,
        super(const SettingsState());

  void loadSettings() {
    final themeModeIndex = _preferences.getInt(_themeKey) ?? 0;
    final currency = _preferences.getString(_currencyKey) ?? 'UZS';

    emit(SettingsState(
      themeMode: ThemeMode.values[themeModeIndex],
      currency: currency,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _preferences.setInt(_themeKey, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setCurrency(String currency) async {
    await _preferences.setString(_currencyKey, currency);
    emit(state.copyWith(currency: currency));
  }
}
