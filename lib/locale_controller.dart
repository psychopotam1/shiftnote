import 'package:flutter/material.dart';

import 'services/settings_service.dart';

class LocaleController extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  Locale? _locale;
  String _raw = 'system';

  Locale? get locale => _locale;
  String get raw => _raw;

  Future<void> load() async {
    final settings = await _settingsService.loadSettings();
    _raw = settings.localeCode;
    _locale = _toLocale(_raw);
    notifyListeners();
  }

  Future<void> setLocaleCode(String value) async {
    final settings = await _settingsService.loadSettings();
    final updated = settings.copyWith(localeCode: value);
    await _settingsService.saveSettings(updated);

    _raw = value;
    _locale = _toLocale(value);
    notifyListeners();
  }

  Locale? _toLocale(String value) {
    switch (value) {
      case 'en':
        return const Locale('en');
      case 'uk':
        return const Locale('uk');
      case 'ru':
        return const Locale('ru');
      case 'system':
      default:
        return null;
    }
  }
}