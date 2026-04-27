import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../l10n/generated/app_localizations.dart';
import '../locale_controller.dart';
import '../models/app_settings.dart';
import '../models/day_entry.dart';
import '../models/shift_entry.dart';
import '../services/ad_service.dart';
import '../services/pro_service.dart';
import '../services/settings_service.dart';
import '../services/shifts_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/background_orb.dart';
import '../widgets/day_card.dart';
import '../widgets/glass_parts.dart';
import 'add_shift_screen.dart';
import 'batch_template_screen.dart';
import 'day_details_screen.dart';
import 'settings_screen.dart';
import 'summary_screen.dart';

class MonthScreen extends StatefulWidget {
  const MonthScreen({
    super.key,
    required this.localeController,
  });

  final LocaleController localeController;

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  final ShiftsService _shiftsService = ShiftsService();
  final SettingsService _settingsService = SettingsService();
  final ProService _proService = ProService();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isPro = false;

  late DateTime _visibleMonth;
  List<DayEntry?> _gridItems = <DayEntry?>[];

  final Set<DateTime> _selectedDays = <DateTime>{};
  bool _selectionMode = false;
  bool _isLoading = true;

  AppSettings _settings = AppSettings.defaults();

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateHelpers.monthStart(DateHelpers.now());
    _loadMonth(_visibleMonth);
    _refreshPro();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isPro = await _proService.isPro();
      if (isPro) return;

      await AdService.instance.warmUpAfterFirstFrame();
      final banner = await AdService.instance.createAdaptiveBanner(
        context: context,
      );

      if (!mounted) return;

      if (banner != null) {
        setState(() {
          _bannerAd = banner;
          _isBannerLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _refreshPro() async {
    final isPro = await _proService.isPro();

    if (!mounted) return;

    if (isPro) {
      _bannerAd?.dispose();
      _bannerAd = null;
    }

    setState(() {
      _isPro = isPro;
      if (isPro) {
        _isBannerLoaded = false;
      }
    });
  }

  Future<void> _loadMonth(
      DateTime month, {
        bool preserveSelection = false,
      }) async {
    final visibleMonth = DateHelpers.monthStart(month);
    final sampleDays = DateHelpers.generateSampleMonth(visibleMonth);
    final savedShifts = await _shiftsService.getAllShifts();
    final settings = await _settingsService.loadSettings();
    final isPro = await _proService.isPro();

    final List<DayEntry> mergedDays = sampleDays.map((entry) {
      final key =
          '${entry.date.year.toString().padLeft(4, '0')}-'
          '${entry.date.month.toString().padLeft(2, '0')}-'
          '${entry.date.day.toString().padLeft(2, '0')}';

      final ShiftEntry? saved = savedShifts[key];

      if (saved == null) {
        return DayEntry(
          date: entry.date,
          type: DayCellType.empty,
          hoursLabel: '',
          overtimeLabel: '',
          amountLabel: '',
          projectName: '',
          paymentStatus: null,
        );
      }

      if (saved.isDayOff) {
        return DayEntry(
          date: entry.date,
          type: DayCellType.off,
          hoursLabel: 'Day off',
          overtimeLabel: '',
          amountLabel: '',
          projectName: '',
          paymentStatus: null,
        );
      }

      return DayEntry(
        date: entry.date,
        type: saved.isOvertime ? DayCellType.overtime : DayCellType.shift,
        hoursLabel: '${saved.startTime}-${saved.endTime}',
        overtimeLabel: saved.isOvertime
            ? '+${saved.overtimeHours.toStringAsFixed(saved.overtimeHours == saved.overtimeHours.roundToDouble() ? 0 : 1)} OT'
            : '',
        amountLabel: DateHelpers.formatMoney(
          saved.total,
          currencyCode: settings.currencyCode,
        ),
        projectName: saved.projectName,
        paymentStatus: saved.paymentStatus,
      );
    }).toList();

    final int leadingEmptyCount =
        DateTime(visibleMonth.year, visibleMonth.month, 1).weekday - 1;

    final List<DayEntry?> gridItems = <DayEntry?>[
      ...List<DayEntry?>.filled(leadingEmptyCount, null),
      ...mergedDays,
    ];

    if (!mounted) return;

    setState(() {
      _settings = settings;
      _isPro = isPro;
      _visibleMonth = visibleMonth;
      _gridItems = gridItems;

      if (!preserveSelection) {
        _selectedDays.clear();
        _selectionMode = false;
      }

      _isLoading = false;
    });
  }

  Future<void> _goToPreviousMonth() async {
    await _loadMonth(
      DateHelpers.previousMonth(_visibleMonth),
      preserveSelection: _selectionMode,
    );
  }

  Future<void> _goToNextMonth() async {
    await _loadMonth(
      DateHelpers.nextMonth(_visibleMonth),
      preserveSelection: _selectionMode,
    );
  }

  Future<void> _handleTap(DayEntry entry) async {
    if (_selectionMode) {
      setState(() {
        final DateTime key = _dateOnly(entry.date);

        if (_selectedDays.any((d) => DateHelpers.isSameDate(d, key))) {
          _selectedDays.removeWhere((d) => DateHelpers.isSameDate(d, key));
        } else {
          _selectedDays.add(key);
        }

        if (_selectedDays.isEmpty) {
          _selectionMode = false;
        }
      });
      return;
    }

    await _openDayScreen(entry);
  }

  void _handleLongPress(DayEntry entry) {
    setState(() {
      _selectionMode = true;
      final DateTime key = _dateOnly(entry.date);

      if (!_selectedDays.any((d) => DateHelpers.isSameDate(d, key))) {
        _selectedDays.add(key);
      }
    });
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _openDayScreen(DayEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DayDetailsScreen(entry: entry),
      ),
    );

    await _loadMonth(_visibleMonth);
    await _refreshPro();
  }

  Future<void> _openAddShift() async {
    DateTime targetDate = DateHelpers.now();

    if (_selectedDays.isNotEmpty) {
      final List<DateTime> sorted = _selectedDays.toList()
        ..sort((a, b) => a.compareTo(b));
      targetDate = sorted.first;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AddShiftScreen(initialDate: targetDate),
      ),
    );

    if (result == true) {
      await _loadMonth(_visibleMonth);
      await _refreshPro();
    }
  }

  Future<void> _openBatchTemplate() async {
    if (_selectedDays.isEmpty) return;

    final sorted = _selectedDays.toList()..sort((a, b) => a.compareTo(b));

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => BatchTemplateScreen(selectedDates: sorted),
      ),
    );

    if (result == true) {
      await _loadMonth(_visibleMonth);
      await _refreshPro();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          localeController: widget.localeController,
        ),
      ),
    );

    await _loadMonth(_visibleMonth);
    await _refreshPro();
  }

  Future<void> _buy() async {
    try {
      await _proService.buyPro();

      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final updated = await _proService.isPro();

        if (!mounted) return;

        if (updated) {
          _bannerAd?.dispose();
          _bannerAd = null;

          setState(() {
            _isPro = true;
            _isBannerLoaded = false;
          });
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase is still processing. Please wait a moment.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openSummary() async {
    if (_selectedDays.isEmpty) return;

    final List<DateTime> sorted = _selectedDays.toList()
      ..sort((a, b) => a.compareTo(b));

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SummaryScreen(selectedDates: sorted),
      ),
    );

    await _loadMonth(_visibleMonth);
    await _refreshPro();
  }

  Future<ShiftEntry?> _getSingleSelectedShift() async {
    if (_selectedDays.length != 1) return null;
    final date = _selectedDays.first;
    return _shiftsService.getShift(date);
  }

  Future<void> _selectNext10() async {
    final l10n = AppLocalizations.of(context)!;
    final seedShift = await _getSingleSelectedShift();

    if (seedShift == null || seedShift.isDayOff) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectOneSavedShiftFirst)),
      );
      return;
    }

    final projectName = seedShift.projectName.trim();
    if (projectName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectedShiftHasNoProjectName)),
      );
      return;
    }

    final shifts = await _shiftsService.getShiftsByProject(projectName);
    final nextTen = shifts
        .where((s) => !s.isDayOff && s.paymentStatus != PaymentStatus.paid)
        .take(10)
        .toList();

    if (nextTen.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noUnpaidSentShiftsLeft)),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _selectionMode = true;
      _selectedDays
        ..clear()
        ..addAll(nextTen.map((s) => _dateOnly(s.date)));
    });
  }

  Future<void> _markSelectedPaid() async {
    if (_selectedDays.isEmpty) return;

    await _shiftsService.updateShiftStatuses(
      _selectedDays.toList(),
      PaymentStatus.paid,
    );

    await _loadMonth(_visibleMonth);
  }

  Future<void> _markSelectedUnpaid() async {
    if (_selectedDays.isEmpty) return;

    await _shiftsService.updateShiftStatuses(
      _selectedDays.toList(),
      PaymentStatus.unpaid,
    );

    await _loadMonth(_visibleMonth);
  }

  void _clearSelection() {
    setState(() {
      _selectedDays.clear();
      _selectionMode = false;
    });
  }

  bool _isSelected(DateTime date) {
    return _selectedDays.any((d) => DateHelpers.isSameDate(d, date));
  }

  int get _overtimeDaysCount {
    return _gridItems
        .whereType<DayEntry>()
        .where((d) => d.type == DayCellType.overtime)
        .length;
  }

  List<DayEntry> get _selectedEntries {
    return _gridItems
        .whereType<DayEntry>()
        .where((entry) => _isSelected(entry.date))
        .toList();
  }

  bool get _canSelectNext10 {
    if (_selectedDays.length != 1) return false;

    final selected = _selectedEntries;
    if (selected.length != 1) return false;

    return selected.first.projectName.trim().isNotEmpty;
  }

  bool get _hasUnpaidSelected {
    return _selectedEntries.any((e) => e.paymentStatus == PaymentStatus.unpaid);
  }

  bool get _hasSentSelected {
    return _selectedEntries.any((e) => e.paymentStatus == PaymentStatus.sent);
  }

  bool get _hasPaidSelected {
    return _selectedEntries.any((e) => e.paymentStatus == PaymentStatus.paid);
  }

  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xFF8EA3FF).withOpacity(0.22),
            const Color(0xFF6D7FEA).withOpacity(0.16),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFB9C5FF).withOpacity(0.24),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF8EA3FF).withOpacity(0.10),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _buy,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.14),
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_moon_rounded,
                    color: Color(0xFFD6DEFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Turn off ads',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Auto backup included',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(AppLocalizations l10n, DateTime deviceNow) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(
          color: Colors.white.withOpacity(0.11),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFC264).withOpacity(0.12),
                border: Border.all(
                  color: const Color(0xFFFFC264).withOpacity(0.22),
                ),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: const Color(0xFFFFC264).withOpacity(0.95),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_overtimeDaysCount} ${l10n.overtimeDaysThisMonth}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (DateHelpers.isSameDate(
              DateHelpers.monthStart(deviceNow),
              _visibleMonth,
            ))
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8EA3FF).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.current,
                  style: const TextStyle(
                    color: Color(0xFFB9C5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final DateTime deviceNow = DateHelpers.now();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF070A10),
              Color(0xFF0E1420),
              Color(0xFF0B1018),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const BackgroundOrb(
              size: 220,
              top: -70,
              left: -40,
              color: Color(0x338EA3FF),
            ),
            const BackgroundOrb(
              size: 190,
              top: 110,
              right: -60,
              color: Color(0x22FFC264),
            ),
            const BackgroundOrb(
              size: 260,
              bottom: -120,
              left: 30,
              color: Color(0x158EA3FF),
            ),
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _selectionMode
                              ? Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.selection,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.9,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedDays.length} ${l10n.daysSelected}',
                                style: TextStyle(
                                  color:
                                  Colors.white.withOpacity(0.62),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                              : Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                DateHelpers.monthTitle(
                                  _visibleMonth,
                                ),
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateHelpers.monthSubtitle(
                                  _visibleMonth,
                                ),
                                style: TextStyle(
                                  color:
                                  Colors.white.withOpacity(0.62),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectionMode)
                          TopGlassButton(
                            icon: Icons.close,
                            onTap: _clearSelection,
                          )
                        else
                          Row(
                            children: <Widget>[
                              TopGlassButton(
                                icon: Icons.chevron_left_rounded,
                                onTap: _goToPreviousMonth,
                              ),
                              const SizedBox(width: 8),
                              TopGlassButton(
                                icon: Icons.chevron_right_rounded,
                                onTap: _goToNextMonth,
                              ),
                              const SizedBox(width: 8),
                              TopGlassButton(
                                icon: Icons.settings_rounded,
                                onTap: _openSettings,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (_selectionMode)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            GlassActionChip(
                              label: l10n.template,
                              icon: Icons.edit_calendar_rounded,
                              onTap: _openBatchTemplate,
                            ),
                            const SizedBox(width: 8),
                            if (_canSelectNext10) ...<Widget>[
                              GlassActionChip(
                                label: l10n.nextTen,
                                icon: Icons
                                    .playlist_add_check_circle_outlined,
                                onTap: _selectNext10,
                              ),
                              const SizedBox(width: 8),
                            ],
                            GlassActionChip(
                              label: l10n.calculate,
                              icon: Icons.calculate_outlined,
                              onTap: _openSummary,
                            ),
                            if (_hasSentSelected) ...<Widget>[
                              const SizedBox(width: 8),
                              GlassActionChip(
                                label: l10n.markPaid,
                                icon: Icons.check_circle_rounded,
                                onTap: _markSelectedPaid,
                              ),
                            ],
                            if (_hasPaidSelected ||
                                _hasSentSelected) ...<Widget>[
                              const SizedBox(width: 8),
                              GlassActionChip(
                                label: l10n.markUnpaid,
                                icon: Icons.restart_alt_rounded,
                                onTap: _markSelectedUnpaid,
                              ),
                            ],
                            if (_hasUnpaidSelected) ...<Widget>[
                              const SizedBox(width: 8),
                              GlassActionChip(
                                label: l10n.shareAction,
                                icon: Icons.share_rounded,
                                onTap: _openSummary,
                              ),
                            ],
                            const SizedBox(width: 8),
                            GlassActionChip(
                              label: l10n.clear,
                              icon: Icons.close_rounded,
                              onTap: _clearSelection,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                      child: _isPro
                          ? _buildStatsCard(l10n, deviceNow)
                          : _buildPromoCard(),
                    ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;

                        if (velocity < -300) {
                          _goToNextMonth();
                        } else if (velocity > 300) {
                          _goToPreviousMonth();
                        }
                      },
                      child: Padding(
                        padding:
                        const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _gridItems.length,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                          itemBuilder: (
                              BuildContext context,
                              int index,
                              ) {
                            final DayEntry? entry = _gridItems[index];

                            if (entry == null) {
                              return const SizedBox.shrink();
                            }

                            return DayCard(
                              entry: entry,
                              isSelected: _isSelected(entry.date),
                              selectionMode: _selectionMode,
                              onTap: () => _handleTap(entry),
                              onLongPress: () => _handleLongPress(entry),
                              showAmount: _settings.showAmountsOnCalendar,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!_isPro && _isBannerLoaded && _bannerAd != null)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SizedBox(
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF8EA3FF).withOpacity(0.28),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openAddShift,
          backgroundColor: const Color(0xFF8EA3FF),
          foregroundColor: Colors.white,
          elevation: 0,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}