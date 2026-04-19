import 'package:flutter/material.dart';

import '../models/day_entry.dart';
import '../models/shift_entry.dart';
import '../utils/date_helpers.dart';
import 'glass_parts.dart';

class DayCard extends StatelessWidget {
  const DayCard({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.showAmount,
  });

  final DayEntry entry;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool showAmount;

  @override
  Widget build(BuildContext context) {
    final style = _style(entry.type, isSelected);
    final bool isToday = DateHelpers.isToday(entry.date);
    final String weekday = _weekdayShort(context, entry.date.weekday);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: GlassShadowWrapper(
        radius: 26,
        blur: isSelected ? 12 : 8,
        opacity: isSelected ? 0.12 : (isToday ? 0.10 : 0.06),
        color: isToday ? const Color(0xFFB9C5FF) : style.shadowColor,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: style.fill,
            border: Border.all(
              color: isToday ? const Color(0xFFB9C5FF) : style.border,
              width: isToday ? 1.4 : (isSelected ? 1.2 : 1.0),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool veryCompact = constraints.maxHeight < 155;

              final double dayFontSize = veryCompact ? 22 : 24;
              final double weekdayFontSize = veryCompact ? 10 : 11;
              final double hoursFontSize = veryCompact ? 15 : 18;
              final double amountFontSize = veryCompact ? 11 : 13;
              final double projectFontSize = veryCompact ? 10 : 11;
              final double badgeFontSize = veryCompact ? 10 : 11;
              final double todayFontSize = veryCompact ? 8 : 9;
              final double horizontalPadding = veryCompact ? 12 : 14;
              final double verticalPadding = veryCompact ? 12 : 14;

              final statusColor = _statusColor(entry.paymentStatus);
              final localeCode = Localizations.localeOf(context).languageCode;
              final todayText = localeCode == 'uk'
                  ? 'СЬОГОДНІ'
                  : localeCode == 'ru'
                  ? 'СЕГОДНЯ'
                  : 'TODAY';

              return Stack(
                children: <Widget>[
                  if (entry.type != DayCellType.empty)
                    Positioned(
                      top: -14,
                      right: -10,
                      child: Container(
                        width: veryCompact ? 48 : 58,
                        height: veryCompact ? 48 : 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: style.accent.withOpacity(0.06),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${entry.day}',
                                  style: TextStyle(
                                    fontSize: dayFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: style.primaryText,
                                    letterSpacing: -0.8,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  weekday,
                                  style: TextStyle(
                                    fontSize: weekdayFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.46),
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (selectionMode)
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: veryCompact ? 18 : 20,
                                color: style.accent,
                              )
                            else if (entry.paymentStatus != null)
                              Container(
                                width: veryCompact ? 10 : 11,
                                height: veryCompact ? 10 : 11,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              )
                            else if (isToday)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: veryCompact ? 6 : 7,
                                    vertical: veryCompact ? 3 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                    const Color(0xFF8EA3FF).withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFB9C5FF)
                                          .withOpacity(0.24),
                                    ),
                                  ),
                                  child: Text(
                                    todayText,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: todayFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFB9C5FF),
                                      letterSpacing: 0.2,
                                      height: 1,
                                    ),
                                  ),
                                )
                              else if (entry.type != DayCellType.empty)
                                  Container(
                                    width: veryCompact ? 8 : 9,
                                    height: veryCompact ? 8 : 9,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: style.accent,
                                    ),
                                  ),
                          ],
                        ),
                        SizedBox(height: veryCompact ? 8 : 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              if (entry.hoursLabel.isNotEmpty)
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        entry.hoursLabel,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: hoursFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: style.primaryText,
                                          height: 1.05,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (entry.projectName.isNotEmpty) ...<Widget>[
                                SizedBox(height: veryCompact ? 4 : 6),
                                Flexible(
                                  child: Text(
                                    entry.projectName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: projectFontSize,
                                      color: Colors.white.withOpacity(0.58),
                                      fontWeight: FontWeight.w600,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                              if (entry.overtimeLabel.isNotEmpty) ...<Widget>[
                                SizedBox(height: veryCompact ? 5 : 6),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: veryCompact ? 7 : 8,
                                    vertical: veryCompact ? 4 : 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: style.badge,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: style.accent.withOpacity(0.14),
                                    ),
                                  ),
                                  child: Text(
                                    entry.overtimeLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: badgeFontSize,
                                      fontWeight: FontWeight.w700,
                                      color: style.accent,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                              if (showAmount && entry.amountLabel.isNotEmpty) ...<Widget>[
                                SizedBox(height: veryCompact ? 6 : 8),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        entry.amountLabel,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: amountFontSize,
                                          color: style.secondaryText,
                                          fontWeight: FontWeight.w500,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _weekdayShort(BuildContext context, int weekday) {
    final locale = Localizations.localeOf(context).languageCode;

    if (locale == 'uk') {
      switch (weekday) {
        case DateTime.monday:
          return 'Пн';
        case DateTime.tuesday:
          return 'Вт';
        case DateTime.wednesday:
          return 'Ср';
        case DateTime.thursday:
          return 'Чт';
        case DateTime.friday:
          return 'Пт';
        case DateTime.saturday:
          return 'Сб';
        case DateTime.sunday:
          return 'Нд';
      }
    }

    if (locale == 'ru') {
      switch (weekday) {
        case DateTime.monday:
          return 'Пн';
        case DateTime.tuesday:
          return 'Вт';
        case DateTime.wednesday:
          return 'Ср';
        case DateTime.thursday:
          return 'Чт';
        case DateTime.friday:
          return 'Пт';
        case DateTime.saturday:
          return 'Сб';
        case DateTime.sunday:
          return 'Вс';
      }
    }

    switch (weekday) {
      case DateTime.monday:
        return 'Mo';
      case DateTime.tuesday:
        return 'Tu';
      case DateTime.wednesday:
        return 'We';
      case DateTime.thursday:
        return 'Th';
      case DateTime.friday:
        return 'Fr';
      case DateTime.saturday:
        return 'Sa';
      case DateTime.sunday:
        return 'Su';
      default:
        return '';
    }
  }

  Color _statusColor(PaymentStatus? status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return const Color(0xFFFF6B6B);
      case PaymentStatus.sent:
        return const Color(0xFFFFC264);
      case PaymentStatus.paid:
        return const Color(0xFF78E08F);
      case null:
        return Colors.transparent;
    }
  }

  DayStyle _style(DayCellType type, bool selected) {
    switch (type) {
      case DayCellType.empty:
        return DayStyle(
          fill: selected
              ? const Color(0xFF8EA3FF).withOpacity(0.16)
              : const Color(0xFF161D29).withOpacity(0.82),
          border: selected
              ? const Color(0xFF8EA3FF).withOpacity(0.36)
              : Colors.white.withOpacity(0.06),
          primaryText: Colors.white,
          secondaryText: Colors.white.withOpacity(0.46),
          accent: const Color(0xFF8EA3FF),
          badge: const Color(0xFF8EA3FF).withOpacity(0.14),
          shadowColor: const Color(0xFF8EA3FF),
        );
      case DayCellType.shift:
        return DayStyle(
          fill: selected
              ? const Color(0xFF22324C)
              : const Color(0xFF1B2A41),
          border: selected
              ? const Color(0xFF8EA3FF).withOpacity(0.38)
              : const Color(0xFF8EA3FF).withOpacity(0.14),
          primaryText: Colors.white,
          secondaryText: const Color(0xFFD4DCFF).withOpacity(0.82),
          accent: const Color(0xFF8EA3FF),
          badge: const Color(0xFF8EA3FF).withOpacity(0.14),
          shadowColor: const Color(0xFF8EA3FF),
        );
      case DayCellType.overtime:
        return DayStyle(
          fill: selected
              ? const Color(0xFF3A2B14)
              : const Color(0xFF2E2417),
          border: selected
              ? const Color(0xFFFFC264).withOpacity(0.38)
              : const Color(0xFFFFC264).withOpacity(0.16),
          primaryText: Colors.white,
          secondaryText: const Color(0xFFFFE4B2).withOpacity(0.88),
          accent: const Color(0xFFFFC264),
          badge: const Color(0xFFFFC264).withOpacity(0.14),
          shadowColor: const Color(0xFFFFC264),
        );
      case DayCellType.off:
        return DayStyle(
          fill: selected
              ? const Color(0xFF20242C)
              : const Color(0xFF171B22),
          border: selected
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.06),
          primaryText: Colors.white.withOpacity(0.90),
          secondaryText: Colors.white.withOpacity(0.52),
          accent: Colors.white.withOpacity(0.65),
          badge: Colors.white.withOpacity(0.10),
          shadowColor: Colors.white,
        );
      case DayCellType.planned:
        return DayStyle(
          fill: selected
              ? const Color(0xFF212B3A)
              : const Color(0xFF18212F),
          border: selected
              ? const Color(0xFFB9C5FF).withOpacity(0.34)
              : const Color(0xFF8EA3FF).withOpacity(0.16),
          primaryText: Colors.white,
          secondaryText: Colors.white.withOpacity(0.64),
          accent: const Color(0xFF8EA3FF),
          badge: const Color(0xFF8EA3FF).withOpacity(0.14),
          shadowColor: const Color(0xFF8EA3FF),
        );
    }
  }
}

class DayStyle {
  const DayStyle({
    required this.fill,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.badge,
    required this.shadowColor,
  });

  final Color fill;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color badge;
  final Color shadowColor;
}