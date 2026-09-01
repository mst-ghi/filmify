import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user settings backed by SharedPreferences.
///
/// Exposes: locale (system/en/fa), theme mode, optional API key override and
/// the Persian-numerals toggle. All UI surfaces listen via [Listenable].
class AppSettings extends ChangeNotifier {
  static const _keyLocale = 'settings.locale'; // 'system' | 'en' | 'fa'
  static const _keyThemeMode = 'settings.themeMode'; // system|light|dark
  static const _keyApiKey = 'settings.apiKey';
  static const _keyPersianNumerals = 'settings.persianNumerals';

  final SharedPreferences _prefs;

  AppSettings(this._prefs);

  String get localeTag => _prefs.getString(_keyLocale) ?? 'system';
  ThemeMode get themeMode {
    switch (_prefs.getString(_keyThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Empty string means "use the built-in default key".
  String get apiKey => _prefs.getString(_keyApiKey) ?? '';

  bool get persianNumerals => _prefs.getBool(_keyPersianNumerals) ?? false;

  /// Resolved locale: null means follow the system.
  Locale? get locale =>
      localeTag == 'system' ? null : Locale(localeTag);

  Future<void> setLocaleTag(String tag) async {
    await _prefs.setString(_keyLocale, tag);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final tag = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_keyThemeMode, tag);
    notifyListeners();
  }

  Future<void> setApiKey(String key) async {
    await _prefs.setString(_keyApiKey, key.trim());
    notifyListeners();
  }

  Future<void> setPersianNumerals(bool value) async {
    await _prefs.setBool(_keyPersianNumerals, value);
    notifyListeners();
  }
}
