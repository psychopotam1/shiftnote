import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/shift_entry.dart';
import 'backup_service.dart';
import 'pro_service.dart';
import 'settings_service.dart';

class ShiftsService {
  final BackupService _backupService = BackupService();
  final ProService _proService = ProService();
  final SettingsService _settingsService = SettingsService();

  static const String _storageKey = 'saved_shifts';

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Map<String, dynamic>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<void> _saveRaw(Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_storageKey, jsonEncode(raw));
    if (!saved) throw Exception('Failed to save shifts locally');
    if (!await _proService.isPro()) return;
    try {
      await _backupService.backupNow(raw);
    } catch (_) {
      // Backup must not block local saving.
    }
  }

  Future<void> recalculateShortRest() async {
    await _saveWithShortRestRecalculation(await _loadRaw());
  }

  Future<void> saveShift(ShiftEntry shift) async {
    final raw = await _loadRaw();
    final normalized = shift.copyWith(
      overtimeHours: shift.calculatedRegularOvertimeHours,
      isOvertime: shift.calculatedRegularOvertimeHours > 0 || shift.shortRestHours > 0,
    );
    raw[_dateKey(normalized.date)] = normalized.toMap();
    await _saveWithShortRestRecalculation(raw);
  }

  Future<void> _saveWithShortRestRecalculation(Map<String, dynamic> raw) async {
    final settings = await _settingsService.loadSettings();
    final calculated = _applyShortRestRules(raw, settings);
    await _saveRaw(calculated);
  }

  Map<String, dynamic> _applyShortRestRules(
    Map<String, dynamic> raw,
    AppSettings settings,
  ) {
    final workShifts = raw.entries
        .where((entry) => entry.value is Map)
        .map((entry) => ShiftEntry.fromMap(Map<String, dynamic>.from(entry.value as Map)))
        .where((shift) => !shift.isDayOff)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    ShiftEntry? previous;
    for (final shift in workShifts) {
      double shortRestHours = 0;
      if (settings.shortRestEnabled && previous != null) {
        final previousEnd = _dateTimeForTime(previous.date, previous.endTime, isEnd: true, startTime: previous.startTime);
        final currentStart = _dateTimeForTime(shift.date, shift.startTime);
        if (previousEnd != null && currentStart != null) {
          final restMinutes = currentStart.difference(previousEnd).inMinutes;
          final limitMinutes = (settings.minimumRestHours * 60).round();
          if (restMinutes >= 0 && restMinutes < limitMinutes) {
            shortRestHours = settings.shortRestBonusHours;
          }
        }
      }
      final overtimeHours = shift.calculatedRegularOvertimeHours;
      final updated = shift.copyWith(
        overtimeHours: overtimeHours,
        shortRestHours: shortRestHours,
        isOvertime: overtimeHours > 0 || shortRestHours > 0,
      );
      raw[_dateKey(shift.date)] = updated.toMap();
      previous = updated;
    }
    return raw;
  }

  DateTime? _dateTimeForTime(
    DateTime date,
    String time, {
    bool isEnd = false,
    String startTime = '',
  }) {
    final minutes = _parseMinutes(time);
    if (minutes < 0) return null;
    var dayOffset = 0;
    if (isEnd) {
      final startMinutes = _parseMinutes(startTime);
      if (startMinutes >= 0 && minutes < startMinutes) dayOffset = 1;
    }
    return DateTime(date.year, date.month, date.day + dayOffset, minutes ~/ 60, minutes % 60);
  }

  Future<double> calculateShortRestPreview({
    required DateTime date,
    required String startTime,
  }) async {
    final settings = await _settingsService.loadSettings();
    if (!settings.shortRestEnabled) return 0;
    final all = (await getAllShifts()).values
        .where((shift) => !shift.isDayOff && shift.date.isBefore(date))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (all.isEmpty) return 0;
    final previous = all.last;
    final previousEnd = _dateTimeForTime(previous.date, previous.endTime, isEnd: true, startTime: previous.startTime);
    final currentStart = _dateTimeForTime(date, startTime);
    if (previousEnd == null || currentStart == null) return 0;
    final restMinutes = currentStart.difference(previousEnd).inMinutes;
    final limitMinutes = (settings.minimumRestHours * 60).round();
    return restMinutes >= 0 && restMinutes < limitMinutes ? settings.shortRestBonusHours : 0;
  }

  Future<ShiftEntry?> getShift(DateTime date) async {
    final raw = await _loadRaw();
    final data = raw[_dateKey(date)];
    if (data == null || data is! Map) return null;
    return ShiftEntry.fromMap(Map<String, dynamic>.from(data));
  }

  Future<Map<String, ShiftEntry>> getAllShifts() async {
    final raw = await _loadRaw();
    final result = <String, ShiftEntry>{};
    raw.forEach((key, value) {
      if (value is Map) result[key] = ShiftEntry.fromMap(Map<String, dynamic>.from(value));
    });
    return result;
  }

  Future<List<ShiftEntry>> getShiftsByProject(String projectName) async {
    final normalized = projectName.trim().toLowerCase();
    if (normalized.isEmpty) return <ShiftEntry>[];
    final all = await getAllShifts();
    return all.values.where((shift) => shift.projectName.trim().toLowerCase() == normalized).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> updateShiftStatus(DateTime date, PaymentStatus status) async {
    final existing = await getShift(date);
    if (existing == null) return;
    await saveShift(existing.copyWith(paymentStatus: status));
  }

  Future<void> updateShiftStatuses(List<DateTime> dates, PaymentStatus status) async {
    for (final date in dates) {
      await updateShiftStatus(date, status);
    }
  }

  int _parseDurationHours(String value) {
    // Accept old/new localized values: "12h", "12 h", "12ч", "12 год", etc.
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? 0 : int.tryParse(match.group(0)!) ?? 0;
  }

  int _parseMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return -1;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return -1;
    return hour * 60 + minute;
  }

  double _recalculateOvertimeHours({
    required String startTime,
    required String endTime,
    required String shiftDuration,
    required bool ignoreFirst15MinOfFirstOtHour,
  }) {
    final durationHours = _parseDurationHours(shiftDuration);
    if (durationHours <= 0) return 0;
    final start = _parseMinutes(startTime);
    final endRaw = _parseMinutes(endTime);
    if (start < 0 || endRaw < 0) return 0;
    var end = endRaw;
    if (end < start) end += 1440;
    final diff = end - (start + durationHours * 60);
    if (diff <= 0) return 0;
    if (ignoreFirst15MinOfFirstOtHour && diff <= 15) return 0;
    return (diff / 60).ceil().toDouble();
  }

  Future<void> applyTemplateToDates({
    required List<DateTime> dates,
    required String shiftDuration,
    required String projectName,
    required String productionName,
    required double baseRate,
    required double overtimeRate,
    required String location,
    required String notes,
    required bool ignoreFirst15MinOfFirstOtHour,
  }) async {
    final raw = await _loadRaw();
    for (final rawDate in dates) {
      final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
      final existingData = raw[_dateKey(date)];
      final existing = existingData is Map ? ShiftEntry.fromMap(Map<String, dynamic>.from(existingData)) : null;
      final startTime = existing?.startTime ?? '';
      final endTime = existing?.endTime ?? '';
      final overtimeHours = _recalculateOvertimeHours(
        startTime: startTime,
        endTime: endTime,
        shiftDuration: shiftDuration,
        ignoreFirst15MinOfFirstOtHour: ignoreFirst15MinOfFirstOtHour,
      );
      raw[_dateKey(date)] = ShiftEntry(
        date: date,
        startTime: startTime,
        endTime: endTime,
        shiftDuration: shiftDuration,
        projectName: projectName.trim(),
        productionName: productionName.trim(),
        baseRate: baseRate,
        overtimeHours: overtimeHours,
        shortRestHours: existing?.shortRestHours ?? 0,
        overtimeRate: overtimeRate,
        transportExpense: existing?.transportExpense ?? 0,
        extraServiceTitle: existing?.extraServiceTitle ?? '',
        extraServiceAmount: existing?.extraServiceAmount ?? 0,
        location: location.trim(),
        notes: notes.trim(),
        isOvertime: overtimeHours > 0,
        ignoreFirst15MinOfFirstOtHour: ignoreFirst15MinOfFirstOtHour,
        paymentStatus: existing?.paymentStatus ?? PaymentStatus.unpaid,
        isDayOff: false,
      ).toMap();
    }
    await _saveWithShortRestRecalculation(raw);
  }

  Future<void> saveDayOff(DateTime date) async {
    await saveShift(ShiftEntry(
      date: DateTime(date.year, date.month, date.day),
      startTime: '', endTime: '', shiftDuration: '', projectName: '', productionName: '',
      baseRate: 0, overtimeHours: 0, overtimeRate: 0, transportExpense: 0,
      location: '', notes: '', isOvertime: false,
      ignoreFirst15MinOfFirstOtHour: false, paymentStatus: PaymentStatus.unpaid, isDayOff: true,
    ));
  }

  Future<void> clearDay(DateTime date) async {
    final raw = await _loadRaw();
    raw.remove(_dateKey(date));
    await _saveWithShortRestRecalculation(raw);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> saveShiftFromMap(String key, dynamic data) async {
    final raw = await _loadRaw();
    if (data is Map<String, dynamic>) {
      raw[key] = data;
      await _saveWithShortRestRecalculation(raw);
    }
  }
}
