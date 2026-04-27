import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service.dart';
import 'pro_service.dart';
import '../models/shift_entry.dart';

class ShiftsService {
  final BackupService _backupService = BackupService();
  final ProService _proService = ProService();

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

    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{};
  }

  Future<void> _saveRaw(Map<String, dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();

    final saved = await prefs.setString(_storageKey, jsonEncode(raw));
    if (!saved) {
      throw Exception('Failed to save shifts locally');
    }

    final isPro = await _proService.isPro();
    if (!isPro) return;

    try {
      await _backupService.backupNow(raw);
    } catch (_) {
      // Бэкап не должен ломать сохранение
    }
  
  }

  Future<void> saveShift(ShiftEntry shift) async {
    final raw = await _loadRaw();
    raw[_dateKey(shift.date)] = shift.toMap();
    await _saveRaw(raw);
  }

  Future<ShiftEntry?> getShift(DateTime date) async {
    final raw = await _loadRaw();
    final data = raw[_dateKey(date)];

    if (data == null || data is! Map) {
      return null;
    }

    return ShiftEntry.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  Future<Map<String, ShiftEntry>> getAllShifts() async {
    final raw = await _loadRaw();
    final Map<String, ShiftEntry> result = <String, ShiftEntry>{};

    raw.forEach((key, value) {
      if (value is Map) {
        result[key] = ShiftEntry.fromMap(
          Map<String, dynamic>.from(value),
        );
      }
    });

    return result;
  }

  Future<List<ShiftEntry>> getShiftsByProject(String projectName) async {
    final normalized = projectName.trim().toLowerCase();
    if (normalized.isEmpty) return <ShiftEntry>[];

    final all = await getAllShifts();
    final shifts = all.values.where((shift) {
      return shift.projectName.trim().toLowerCase() == normalized;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return shifts;
  }

  Future<void> updateShiftStatus(
      DateTime date,
      PaymentStatus status,
      ) async {
    final existing = await getShift(date);
    if (existing == null) return;

    final updated = existing.copyWith(paymentStatus: status);
    await saveShift(updated);
  }

  Future<void> updateShiftStatuses(
      List<DateTime> dates,
      PaymentStatus status,
      ) async {
    for (final date in dates) {
      await updateShiftStatus(date, status);
    }
  }

  int _parseDurationHours(String value) {
    final normalized = value.replaceAll('h', '').trim();
    return int.tryParse(normalized) ?? 0;
  }

  int _parseMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return -1;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return -1;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return -1;

    return (hour * 60) + minute;
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

    int end = endRaw;
    if (end < start) {
      end += 1440;
    }

    final plannedEnd = start + (durationHours * 60);
    final diff = end - plannedEnd;

    if (diff <= 0) return 0;

    if (ignoreFirst15MinOfFirstOtHour) {
      if (diff <= 15) return 0;
      return ((diff / 60).ceil()).toDouble();
    }

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
    for (final rawDate in dates) {
      final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
      final existing = await getShift(date);

      final String startTime = existing?.startTime ?? '';
      final String endTime = existing?.endTime ?? '';
      final double transportExpense = existing?.transportExpense ?? 0;
      final PaymentStatus paymentStatus =
          existing?.paymentStatus ?? PaymentStatus.unpaid;

      final double overtimeHours = _recalculateOvertimeHours(
        startTime: startTime,
        endTime: endTime,
        shiftDuration: shiftDuration,
        ignoreFirst15MinOfFirstOtHour: ignoreFirst15MinOfFirstOtHour,
      );

      final shift = ShiftEntry(
        date: date,
        startTime: startTime,
        endTime: endTime,
        shiftDuration: shiftDuration,
        projectName: projectName.trim(),
        productionName: productionName.trim(),
        baseRate: baseRate,
        overtimeHours: overtimeHours,
        overtimeRate: overtimeRate,
        transportExpense: transportExpense,
        location: location.trim(),
        notes: notes.trim(),
        isOvertime: overtimeHours > 0,
        ignoreFirst15MinOfFirstOtHour: ignoreFirst15MinOfFirstOtHour,
        paymentStatus: paymentStatus,
        isDayOff: false,
      );

      await saveShift(shift);
    }
  }

  Future<void> saveDayOff(DateTime date) async {
    final dayOff = ShiftEntry(
      date: DateTime(date.year, date.month, date.day),
      startTime: '',
      endTime: '',
      shiftDuration: '',
      projectName: '',
      productionName: '',
      baseRate: 0,
      overtimeHours: 0,
      overtimeRate: 0,
      transportExpense: 0,
      location: '',
      notes: '',
      isOvertime: false,
      ignoreFirst15MinOfFirstOtHour: false,
      paymentStatus: PaymentStatus.unpaid,
      isDayOff: true,
    );

    await saveShift(dayOff);
  }

  Future<void> clearDay(DateTime date) async {
    final raw = await _loadRaw();
    raw.remove(_dateKey(date));
    await _saveRaw(raw);
  }

  // 👇 ВСТАВЛЯЕШЬ ВОТ ЭТО
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> saveShiftFromMap(String key, dynamic data) async {
    final raw = await _loadRaw();

    if (data is Map<String, dynamic>) {
      raw[key] = data;
      await _saveRaw(raw);
    }
  }
}