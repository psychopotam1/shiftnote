enum PaymentStatus {
  unpaid,
  sent,
  paid,
}

class ShiftEntry {
  final DateTime date;
  final String startTime;
  final String endTime;
  final String shiftDuration;
  final String projectName;
  final String productionName;
  final double baseRate;
  final double overtimeHours;
  final double overtimeRate;
  final double transportExpense;
  final String location;
  final String notes;
  final bool isOvertime;
  final bool ignoreFirst15MinOfFirstOtHour;
  final PaymentStatus paymentStatus;
  final bool isDayOff;

  const ShiftEntry({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.shiftDuration,
    required this.projectName,
    required this.productionName,
    required this.baseRate,
    required this.overtimeHours,
    required this.overtimeRate,
    required this.transportExpense,
    required this.location,
    required this.notes,
    required this.isOvertime,
    required this.ignoreFirst15MinOfFirstOtHour,
    required this.paymentStatus,
    required this.isDayOff,
  });

  double get overtimeTotal => isOvertime ? overtimeHours * overtimeRate : 0;

  double get total => baseRate + overtimeTotal + transportExpense;

  ShiftEntry copyWith({
    DateTime? date,
    String? startTime,
    String? endTime,
    String? shiftDuration,
    String? projectName,
    String? productionName,
    double? baseRate,
    double? overtimeHours,
    double? overtimeRate,
    double? transportExpense,
    String? location,
    String? notes,
    bool? isOvertime,
    bool? ignoreFirst15MinOfFirstOtHour,
    PaymentStatus? paymentStatus,
    bool? isDayOff,
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
      overtimeRate: overtimeRate ?? this.overtimeRate,
      transportExpense: transportExpense ?? this.transportExpense,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isOvertime: isOvertime ?? this.isOvertime,
      ignoreFirst15MinOfFirstOtHour:
      ignoreFirst15MinOfFirstOtHour ??
          this.ignoreFirst15MinOfFirstOtHour,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isDayOff: isDayOff ?? this.isDayOff,
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
      'overtimeHours': overtimeHours,
      'overtimeRate': overtimeRate,
      'transportExpense': transportExpense,
      'location': location,
      'notes': notes,
      'isOvertime': isOvertime,
      'ignoreFirst15MinOfFirstOtHour': ignoreFirst15MinOfFirstOtHour,
      'paymentStatus': paymentStatus.name,
      'isDayOff': isDayOff,
    };
  }

  factory ShiftEntry.fromMap(Map<String, dynamic> map) {
    final rawStatus = (map['paymentStatus'] ?? 'unpaid') as String;

    return ShiftEntry(
      date: DateTime.parse(map['date'] as String),
      startTime: (map['startTime'] ?? '') as String,
      endTime: (map['endTime'] ?? '') as String,
      shiftDuration: (map['shiftDuration'] ?? '') as String,
      projectName: (map['projectName'] ?? '') as String,
      productionName: (map['productionName'] ?? '') as String,
      baseRate: ((map['baseRate'] ?? 0) as num).toDouble(),
      overtimeHours: ((map['overtimeHours'] ?? 0) as num).toDouble(),
      overtimeRate: ((map['overtimeRate'] ?? 0) as num).toDouble(),
      transportExpense: ((map['transportExpense'] ?? 0) as num).toDouble(),
      location: (map['location'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      isOvertime: (map['isOvertime'] ?? false) as bool,
      ignoreFirst15MinOfFirstOtHour:
      (map['ignoreFirst15MinOfFirstOtHour'] ?? false) as bool,
      paymentStatus: PaymentStatus.values.firstWhere(
            (value) => value.name == rawStatus,
        orElse: () => PaymentStatus.unpaid,
      ),
      isDayOff: (map['isDayOff'] ?? false) as bool,
    );
  }
}