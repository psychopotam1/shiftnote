import '../models/day_entry.dart';

class DateHelpers {
  static DateTime now() => DateTime.now();

  static bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    return isSameDate(date, now());
  }

  static DateTime monthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime previousMonth(DateTime date) {
    return DateTime(date.year, date.month - 1, 1);
  }

  static DateTime nextMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 1);
  }

  static int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  static String monthName(
      int month, {
        String localeCode = 'en',
      }) {
    const en = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const uk = <String>[
      'Січень',
      'Лютий',
      'Березень',
      'Квітень',
      'Травень',
      'Червень',
      'Липень',
      'Серпень',
      'Вересень',
      'Жовтень',
      'Листопад',
      'Грудень',
    ];

    const ru = <String>[
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];

    switch (localeCode) {
      case 'uk':
        return uk[month - 1];
      case 'ru':
        return ru[month - 1];
      default:
        return en[month - 1];
    }
  }

  static String monthTitle(
      DateTime date, {
        String localeCode = 'en',
      }) {
    return monthName(
      date.month,
      localeCode: localeCode,
    );
  }

  static String monthSubtitle(DateTime date) {
    return '${date.year} · ShiftNote';
  }

  static String formatShortDate(
      DateTime date, {
        String localeCode = 'en',
      }) {
    return '${monthName(date.month, localeCode: localeCode)} ${date.day}, ${date.year}';
  }

  static String currencySymbol(String code) {
    switch (code) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'UAH':
        return '₴';
      case 'GBP':
        return '£';
      case 'PLN':
        return 'zł';
      case 'CAD':
        return r'C$';
      default:
        return code;
    }
  }

  static String formatMoney(
      double value, {
        required String currencyCode,
      }) {
    final symbol = currencySymbol(currencyCode);
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '$symbol$formatted';
  }

  static String formatTimeOfDay(
      int hour,
      int minute, {
        bool use24HourFormat = true,
      }) {
    if (use24HourFormat) {
      final hh = hour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    final int normalizedHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    final String mm = minute.toString().padLeft(2, '0');
    final String period = hour >= 12 ? 'PM' : 'AM';
    return '$normalizedHour:$mm $period';
  }

  static List<DayEntry> generateSampleMonth(DateTime monthDate) {
    final start = monthStart(monthDate);
    final totalDays = daysInMonth(monthDate);

    final List<DayEntry> result = <DayEntry>[];

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(start.year, start.month, day);
      result.add(
        DayEntry(
          date: date,
          type: DayCellType.empty,
          hoursLabel: '',
          overtimeLabel: '',
          amountLabel: '',
          projectName: '',
          paymentStatus: null,
        ),
      );
    }

    return result;
  }
}