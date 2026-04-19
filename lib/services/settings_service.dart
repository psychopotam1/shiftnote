import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService {
  static const String _localeCodeKey = 'locale_code';
  static const String _currencyCodeKey = 'currency_code';
  static const String _use24HourFormatKey = 'use_24_hour_format';
  static const String _defaultBaseRateKey = 'default_base_rate';
  static const String _defaultOvertimeRateKey = 'default_overtime_rate';
  static const String _defaultOvertimeHoursKey = 'default_overtime_hours';
  static const String _defaultStartHourKey = 'default_start_hour';
  static const String _defaultStartMinuteKey = 'default_start_minute';
  static const String _defaultEndHourKey = 'default_end_hour';
  static const String _defaultEndMinuteKey = 'default_end_minute';
  static const String _addToCalendarByDefaultKey =
      'add_to_calendar_by_default';
  static const String _showAmountsOnCalendarKey =
      'show_amounts_on_calendar';
  static const String _ignoreFirst15MinOfFirstOtHourKey =
      'ignore_first_15_min_of_first_ot_hour';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();

    return AppSettings(
      localeCode:
      prefs.getString(_localeCodeKey) ?? defaults.localeCode,
      currencyCode:
      prefs.getString(_currencyCodeKey) ?? defaults.currencyCode,
      use24HourFormat:
      prefs.getBool(_use24HourFormatKey) ?? defaults.use24HourFormat,
      defaultBaseRate:
      prefs.getDouble(_defaultBaseRateKey) ?? defaults.defaultBaseRate,
      defaultOvertimeRate:
      prefs.getDouble(_defaultOvertimeRateKey) ??
          defaults.defaultOvertimeRate,
      defaultOvertimeHours:
      prefs.getDouble(_defaultOvertimeHoursKey) ??
          defaults.defaultOvertimeHours,
      defaultStartHour:
      prefs.getInt(_defaultStartHourKey) ?? defaults.defaultStartHour,
      defaultStartMinute:
      prefs.getInt(_defaultStartMinuteKey) ??
          defaults.defaultStartMinute,
      defaultEndHour:
      prefs.getInt(_defaultEndHourKey) ?? defaults.defaultEndHour,
      defaultEndMinute:
      prefs.getInt(_defaultEndMinuteKey) ?? defaults.defaultEndMinute,
      addToCalendarByDefault:
      prefs.getBool(_addToCalendarByDefaultKey) ??
          defaults.addToCalendarByDefault,
      showAmountsOnCalendar:
      prefs.getBool(_showAmountsOnCalendarKey) ??
          defaults.showAmountsOnCalendar,
      ignoreFirst15MinOfFirstOtHour:
      prefs.getBool(_ignoreFirst15MinOfFirstOtHourKey) ??
          defaults.ignoreFirst15MinOfFirstOtHour,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_localeCodeKey, settings.localeCode);
    await prefs.setString(_currencyCodeKey, settings.currencyCode);
    await prefs.setBool(_use24HourFormatKey, settings.use24HourFormat);
    await prefs.setDouble(_defaultBaseRateKey, settings.defaultBaseRate);
    await prefs.setDouble(
      _defaultOvertimeRateKey,
      settings.defaultOvertimeRate,
    );
    await prefs.setDouble(
      _defaultOvertimeHoursKey,
      settings.defaultOvertimeHours,
    );
    await prefs.setInt(_defaultStartHourKey, settings.defaultStartHour);
    await prefs.setInt(_defaultStartMinuteKey, settings.defaultStartMinute);
    await prefs.setInt(_defaultEndHourKey, settings.defaultEndHour);
    await prefs.setInt(_defaultEndMinuteKey, settings.defaultEndMinute);
    await prefs.setBool(
      _addToCalendarByDefaultKey,
      settings.addToCalendarByDefault,
    );
    await prefs.setBool(
      _showAmountsOnCalendarKey,
      settings.showAmountsOnCalendar,
    );
    await prefs.setBool(
      _ignoreFirst15MinOfFirstOtHourKey,
      settings.ignoreFirst15MinOfFirstOtHour,
    );
  }
}