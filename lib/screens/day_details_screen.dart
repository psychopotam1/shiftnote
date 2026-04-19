// lib/screens/day_details_screen.dart

import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/day_entry.dart';
import '../models/shift_entry.dart';
import '../services/shifts_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/background_orb.dart';
import '../widgets/glass_parts.dart';
import 'add_shift_screen.dart';

class DayDetailsScreen extends StatefulWidget {
  const DayDetailsScreen({
    super.key,
    required this.entry,
  });

  final DayEntry entry;

  @override
  State<DayDetailsScreen> createState() => _DayDetailsScreenState();
}

class _DayDetailsScreenState extends State<DayDetailsScreen> {
  final ShiftsService _shiftsService = ShiftsService();

  ShiftEntry? _savedShift;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  Future<void> _loadShift() async {
    final shift = await _shiftsService.getShift(widget.entry.date);

    if (!mounted) return;

    setState(() {
      _savedShift = shift;
      _isLoading = false;
    });
  }

  bool get _isEmptyDay =>
      _savedShift == null && widget.entry.type == DayCellType.empty;

  Future<void> _openEditor(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddShiftScreen(initialDate: widget.entry.date),
      ),
    );

    if (result == true) {
      await _loadShift();
    }
  }

  Future<void> _markDayOff() async {
    await _shiftsService.saveDayOff(widget.entry.date);
    await _loadShift();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
    final date = widget.entry.date;

    final title =
        '${date.day} ${DateHelpers.monthTitle(date, localeCode: localeCode)} ${date.year}';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070A10),
              Color(0xFF101620),
              Color(0xFF0C1017),
            ],
          ),
        ),
        child: Stack(
          children: [
            const BackgroundOrb(
              size: 220,
              top: -70,
              right: -50,
              color: Color(0x228EA3FF),
            ),
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TopGlassButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 🔥 КАРТОЧКА С ТАПОМ + ИКОНКА
                          GestureDetector(
                            onTap: () => _openEditor(context),
                            child: Stack(
                              children: [
                                GlassCard(
                                  child: Column(
                                    children: [
                                      InfoRow(
                                        label: l10n.status,
                                        value: _savedShift == null
                                            ? l10n.emptyDay
                                            : (_savedShift!.isDayOff
                                            ? l10n.dayOff
                                            : l10n.shift),
                                      ),
                                      InfoRow(
                                        label: l10n.hours,
                                        value: _savedShift == null
                                            ? '—'
                                            : '${_savedShift!.startTime} - ${_savedShift!.endTime}',
                                      ),
                                      InfoRow(
                                        label: l10n.duration,
                                        value: _savedShift?.shiftDuration ??
                                            '—',
                                      ),
                                      InfoRow(
                                        label: l10n.project,
                                        value: _savedShift?.projectName
                                            .isNotEmpty ==
                                            true
                                            ? _savedShift!.projectName
                                            : '—',
                                      ),
                                      InfoRow(
                                        label: l10n.production,
                                        value: _savedShift?.productionName
                                            .isNotEmpty ==
                                            true
                                            ? _savedShift!.productionName
                                            : '—',
                                      ),
                                      InfoRow(
                                        label: l10n.amount,
                                        value: _savedShift == null
                                            ? '—'
                                            : _savedShift!.total
                                            .toString(),
                                        removeBottomPadding: true,
                                      ),
                                    ],
                                  ),
                                ),

                                // 👇 визуальный намёк "можно редактировать"
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SafeArea(
                    top: false,
                    minimum:
                    const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: SoftGlassButton(
                              label: _isEmptyDay
                                  ? l10n.addShift
                                  : l10n.editShift,
                              icon: Icons.edit,
                              onTap: () => _openEditor(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SoftGlassButton(
                              label: l10n.dayOff,
                              icon: Icons.hotel,
                              onTap: _markDayOff,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}