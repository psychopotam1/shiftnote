class AppSettings {
  final String localeCode;
  final String currencyCode;
  final bool use24HourFormat;
  final double defaultBaseRate;
  final double defaultOvertimeRate;
  final double defaultOvertimeHours;
  final int defaultStartHour;
  final int defaultStartMinute;
  final int defaultEndHour;
  final int defaultEndMinute;
  final bool addToCalendarByDefault;
  final bool showAmountsOnCalendar;
  final bool ignoreFirst15MinOfFirstOtHour;

  const AppSettings({
    required this.localeCode,
    required this.currencyCode,
    required this.use24HourFormat,
    required this.defaultBaseRate,
    required this.defaultOvertimeRate,
    required this.defaultOvertimeHours,
    required this.defaultStartHour,
    required this.defaultStartMinute,
    required this.defaultEndHour,
    required this.defaultEndMinute,
    required this.addToCalendarByDefault,
    required this.showAmountsOnCalendar,
    required this.ignoreFirst15MinOfFirstOtHour,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      localeCode: 'system',
      currencyCode: 'USD',
      use24HourFormat: true,
      defaultBaseRate: 240,
      defaultOvertimeRate: 40,
      defaultOvertimeHours: 2,
      defaultStartHour: 8,
      defaultStartMinute: 0,
      defaultEndHour: 18,
      defaultEndMinute: 0,
      addToCalendarByDefault: false,
      showAmountsOnCalendar: false,
      ignoreFirst15MinOfFirstOtHour: false,
    );
  }

  AppSettings copyWith({
    String? localeCode,
    String? currencyCode,
    bool? use24HourFormat,
    double? defaultBaseRate,
    double? defaultOvertimeRate,
    double? defaultOvertimeHours,
    int? defaultStartHour,
    int? defaultStartMinute,
    int? defaultEndHour,
    int? defaultEndMinute,
    bool? addToCalendarByDefault,
    bool? showAmountsOnCalendar,
    bool? ignoreFirst15MinOfFirstOtHour,
  }) {
    return AppSettings(
      localeCode: localeCode ?? this.localeCode,
      currencyCode: currencyCode ?? this.currencyCode,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      defaultBaseRate: defaultBaseRate ?? this.defaultBaseRate,
      defaultOvertimeRate: defaultOvertimeRate ?? this.defaultOvertimeRate,
      defaultOvertimeHours: defaultOvertimeHours ?? this.defaultOvertimeHours,
      defaultStartHour: defaultStartHour ?? this.defaultStartHour,
      defaultStartMinute: defaultStartMinute ?? this.defaultStartMinute,
      defaultEndHour: defaultEndHour ?? this.defaultEndHour,
      defaultEndMinute: defaultEndMinute ?? this.defaultEndMinute,
      addToCalendarByDefault:
      addToCalendarByDefault ?? this.addToCalendarByDefault,
      showAmountsOnCalendar:
      showAmountsOnCalendar ?? this.showAmountsOnCalendar,
      ignoreFirst15MinOfFirstOtHour:
      ignoreFirst15MinOfFirstOtHour ??
          this.ignoreFirst15MinOfFirstOtHour,
    );
  }
}