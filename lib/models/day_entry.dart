import 'shift_entry.dart';

enum DayCellType {
  empty,
  shift,
  overtime,
  off,
  planned,
  continuation,
}

class DayEntry {
  final DateTime date;
  final DayCellType type;
  final String hoursLabel;
  final String amountLabel;
  final String overtimeLabel;
  final String projectName;
  final PaymentStatus? paymentStatus;
  /// For synthetic calendar entries, for example the 00:00-05:00 part
  /// of a night shift that started on the previous day.
  final DateTime? sourceDate;
  final bool isNightContinuation;

  const DayEntry({
    required this.date,
    required this.type,
    this.hoursLabel = '',
    this.amountLabel = '',
    this.overtimeLabel = '',
    this.projectName = '',
    this.paymentStatus,
    this.sourceDate,
    this.isNightContinuation = false,
  });

  int get day => date.day;
}