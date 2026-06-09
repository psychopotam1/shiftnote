import 'shift_entry.dart';

/// A portable report exported by one worker and imported by a coordinator.
/// It contains independent shifts and never modifies the coordinator's calendar.
class MemberReport {
  final String reportId;
  final String participantName;
  final String projectName;
  final String productionName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime exportedAt;
  final int revision;
  final List<ShiftEntry> shifts;

  const MemberReport({
    required this.reportId,
    required this.participantName,
    required this.projectName,
    required this.productionName,
    required this.periodStart,
    required this.periodEnd,
    required this.exportedAt,
    required this.revision,
    required this.shifts,
  });

  double get total => shifts.fold(0.0, (sum, shift) => sum + shift.total);
  double get baseTotal => shifts.fold(0.0, (sum, shift) => sum + shift.baseRate);
  double get overtimeTotal => shifts.fold(0.0, (sum, shift) => sum + shift.overtimeTotal);
  double get transportTotal => shifts.fold(0.0, (sum, shift) => sum + shift.transportExpense);
  double get extraServicesTotal => shifts.fold(0.0, (sum, shift) => sum + shift.extraServiceAmount);

  String get matchKey => '${participantName.trim().toLowerCase()}|${projectName.trim().toLowerCase()}|${periodStart.toIso8601String()}|${periodEnd.toIso8601String()}';

  Map<String, dynamic> toMap() {
    return {
      'format': 'shiftnote_member_report',
      'schemaVersion': 1,
      'reportId': reportId,
      'participantName': participantName,
      'projectName': projectName,
      'productionName': productionName,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'exportedAt': exportedAt.toIso8601String(),
      'revision': revision,
      'shifts': shifts.map((shift) => shift.toMap()).toList(),
    };
  }

  factory MemberReport.fromMap(Map<String, dynamic> map) {
    if (map['format'] != 'shiftnote_member_report') {
      throw const FormatException('This is not a ShiftNote member report');
    }
    final rawShifts = map['shifts'];
    if (rawShifts is! List) {
      throw const FormatException('Report has no shifts');
    }
    return MemberReport(
      reportId: (map['reportId'] ?? '') as String,
      participantName: (map['participantName'] ?? '') as String,
      projectName: (map['projectName'] ?? '') as String,
      productionName: (map['productionName'] ?? '') as String,
      periodStart: DateTime.parse(map['periodStart'] as String),
      periodEnd: DateTime.parse(map['periodEnd'] as String),
      exportedAt: DateTime.parse(map['exportedAt'] as String),
      revision: ((map['revision'] ?? 1) as num).toInt(),
      shifts: rawShifts
          .whereType<Map>()
          .map((item) => ShiftEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
