import 'shift_entry.dart';

enum DayCellType {
  empty,
  shift,
  overtime,
  off,
  planned,
}

class DayEntry {
  final DateTime date;
  final DayCellType type;
  final String hoursLabel;
  final String amountLabel;
  final String overtimeLabel;
  final String projectName;
  final PaymentStatus? paymentStatus;

  const DayEntry({
    required this.date,
    required this.type,
    this.hoursLabel = '',
    this.amountLabel = '',
    this.overtimeLabel = '',
    this.projectName = '',
    this.paymentStatus,
  });

  int get day => date.day;
}