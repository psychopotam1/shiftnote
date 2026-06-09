enum PaymentStatus {
  unpaid,
  sent,
  paid,
}

/// One personal work shift. Imported team reports contain their own ShiftEntry
/// instances; they are never merged into the user's calendar.
class ShiftEntry {
  final DateTime date;
  final String startTime;
  final String endTime;
  final String shiftDuration;
  final String projectName;
  final String productionName;
  final double baseRate;
  final double overtimeHours;
  final double shortRestHours;
  final double overtimeRate;
  final double transportExpense;
  final String extraServiceTitle;
  final double extraServiceAmount;
  final String location;
  final String notes;
  final bool isOvertime;
  final bool ignoreFirst15MinOfFirstOtHour;
  final PaymentStatus paymentStatus;
  final bool isDayOff;
  final bool isNightShift;

  const ShiftEntry({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shiftDuration,
    required this.projectName,
    required this.productionName,
    required this.baseRate,
    required this.overtimeHours,
    this.shortRestHours = 0,
    required this.overtimeRate,
    required this.transportExpense,
    this.extraServiceTitle = '',
    this.extraServiceAmount = 0,
    required this.location,
    required this.notes,
    required this.isOvertime,
    required this.ignoreFirst15MinOfFirstOtHour,
    required this.paymentStatus,
    required this.isDayOff,
    this.isNightShift = false,
  });

  int get plannedDurationHours {
    final match = RegExp(r'\d+').firstMatch(shiftDuration);
    final parsed = match == null ? 0 : (int.tryParse(match.group(0)!) ?? 0);
    if (parsed > 0) return parsed;

    // Backward-compatible fallback: old saved shifts can have an empty
    // shiftDuration. For a shift that clearly crosses midnight, use the
    // normal film-shift day of 12h so night overtime is still calculated.
    if (crossesMidnight) return 12;

    return 0;
  }

  double get calculatedRegularOvertimeHours {
    final durationHours = plannedDurationHours;
    if (durationHours <= 0) return 0;
    final start = _startMinutes;
    final endRaw = _endMinutes;
    if (start == null || endRaw == null) return 0;

    var end = endRaw;
    if (crossesMidnight) end += 1440;

    final diffMinutes = end - (start + durationHours * 60);
    if (diffMinutes <= 0) return 0;
    if (ignoreFirst15MinOfFirstOtHour && diffMinutes <= 15) return 0;
    return (diffMinutes / 60).ceilToDouble();
  }

  double get effectiveOvertimeHours {
    final calculated = calculatedRegularOvertimeHours;
    return calculated > overtimeHours ? calculated : overtimeHours;
  }

  bool get hasOvertime => effectiveOvertimeHours > 0 || shortRestHours > 0;

  double get regularOvertimeTotal => effectiveOvertimeHours * overtimeRate;

  double get shortRestTotal => shortRestHours * overtimeRate;

  double get overtimeTotal => regularOvertimeTotal + shortRestTotal;

  double get extrasTotal => transportExpense + extraServiceAmount;

  double get total => baseRate + overtimeTotal + extrasTotal;

  double get totalAdditionalHours => effectiveOvertimeHours + shortRestHours;


  int? get _startMinutes => _parseTimeMinutes(startTime);

  int? get _endMinutes => _parseTimeMinutes(endTime);

  bool get crossesMidnight => isNightShift;

  bool get endTimeIsBeforeStart {
    final start = _startMinutes;
    final end = _endMinutes;
    if (start == null || end == null) return false;
    return end < start;
  }

  DateTime? get startDateTime {
    final start = _startMinutes;
    if (start == null) return null;
    return DateTime(date.year, date.month, date.day, start ~/ 60, start % 60);
  }

  DateTime? get endDateTime {
    final end = _endMinutes;
    if (end == null) return null;
    return DateTime(date.year, date.month, date.day + (crossesMidnight ? 1 : 0), end ~/ 60, end % 60);
  }

  double get actualDurationHours {
    final start = startDateTime;
    final end = endDateTime;
    if (start == null || end == null) return 0;
    final minutes = end.difference(start).inMinutes;
    if (minutes <= 0) return 0;
    return minutes / 60;
  }

  String get endDaySuffix => crossesMidnight ? ' (+1d)' : '';

  String get timeRangeLabel => '$startTime - $endTime$endDaySuffix';

  String get startDaySegmentLabel {
    if (!crossesMidnight) return timeRangeLabel;
    return '$startTime - 24:00';
  }

  String get nextDaySegmentLabel {
    if (!crossesMidnight) return '';
    return '00:00 - $endTime';
  }

  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  DateTime get nextDate => DateTime(date.year, date.month, date.day + 1);


  static bool _legacyCrossesMidnight(String startTime, String endTime) {
    final start = _parseTimeMinutes(startTime);
    final end = _parseTimeMinutes(endTime);
    if (start == null || end == null) return false;
    return end < start;
  }

  static int? _parseTimeMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  ShiftEntry copyWith({
    DateTime? date,
    String? startTime,
    String? endTime,
    String? shiftDuration,
    String? projectName,
    String? productionName,
    double? baseRate,
    double? overtimeHours,
    double? shortRestHours,
    double? overtimeRate,
    double? transportExpense,
    String? extraServiceTitle,
    double? extraServiceAmount,
    String? location,
    String? notes,
    bool? isOvertime,
    bool? ignoreFirst15MinOfFirstOtHour,
    PaymentStatus? paymentStatus,
    bool? isDayOff,
    bool? isNightShift,
  }) {
    return ShiftEntry(
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shiftDuration: shiftDuration ?? this.shiftDuration,
      projectName: projectName ?? this.projectName,
      productionName: productionName ?? this.productionName,
      baseRate: baseRate ?? this.baseRate,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      shortRestHours: shortRestHours ?? this.shortRestHours,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      transportExpense: transportExpense ?? this.transportExpense,
      extraServiceTitle: extraServiceTitle ?? this.extraServiceTitle,
      extraServiceAmount: extraServiceAmount ?? this.extraServiceAmount,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isOvertime: isOvertime ?? this.isOvertime,
      ignoreFirst15MinOfFirstOtHour:
          ignoreFirst15MinOfFirstOtHour ?? this.ignoreFirst15MinOfFirstOtHour,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isDayOff: isDayOff ?? this.isDayOff,
      isNightShift: isNightShift ?? this.isNightShift,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'shiftDuration': shiftDuration,
      'projectName': projectName,
      'productionName': productionName,
      'baseRate': baseRate,
      'overtimeHours': effectiveOvertimeHours,
      'shortRestHours': shortRestHours,
      'overtimeRate': overtimeRate,
      'transportExpense': transportExpense,
      'extraServiceTitle': extraServiceTitle,
      'extraServiceAmount': extraServiceAmount,
      'location': location,
      'notes': notes,
      'isOvertime': hasOvertime,
      'ignoreFirst15MinOfFirstOtHour': ignoreFirst15MinOfFirstOtHour,
      'paymentStatus': paymentStatus.name,
      'isDayOff': isDayOff,
      'isNightShift': isNightShift,
    };
  }

  factory ShiftEntry.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['paymentStatus'] ?? 'unpaid') as String;
    final overtimeHours = ((map['overtimeHours'] ?? 0) as num).toDouble();
    final shortRestHours = ((map['shortRestHours'] ?? 0) as num).toDouble();
    final startTime = (map['startTime'] ?? '') as String;
    final endTime = (map['endTime'] ?? '') as String;
    final savedNightShift = map['isNightShift'];
    final isNightShift = savedNightShift is bool
        ? savedNightShift
        : _legacyCrossesMidnight(startTime, endTime);

    return ShiftEntry(
      date: DateTime.parse(map['date'] as String),
      startTime: startTime,
      endTime: endTime,
      shiftDuration: (map['shiftDuration'] ?? '') as String,
      projectName: (map['projectName'] ?? '') as String,
      productionName: (map['productionName'] ?? '') as String,
      baseRate: ((map['baseRate'] ?? 0) as num).toDouble(),
      overtimeHours: overtimeHours,
      shortRestHours: shortRestHours,
      overtimeRate: ((map['overtimeRate'] ?? 0) as num).toDouble(),
      transportExpense: ((map['transportExpense'] ?? 0) as num).toDouble(),
      extraServiceTitle: (map['extraServiceTitle'] ?? '') as String,
      extraServiceAmount: ((map['extraServiceAmount'] ?? 0) as num).toDouble(),
      location: (map['location'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      isOvertime: (map['isOvertime'] ?? (overtimeHours + shortRestHours > 0)) as bool,
      ignoreFirst15MinOfFirstOtHour:
          (map['ignoreFirst15MinOfFirstOtHour'] ?? false) as bool,
      paymentStatus: PaymentStatus.values.firstWhere(
        (value) => value.name == rawStatus,
        orElse: () => PaymentStatus.unpaid,
      ),
      isDayOff: (map['isDayOff'] ?? false) as bool,
      isNightShift: isNightShift,
    );
  }
}
