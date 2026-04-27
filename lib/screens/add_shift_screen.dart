import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/glass_time_picker_sheet.dart';
import '../models/app_settings.dart';
import '../models/shift_entry.dart';
import '../services/ad_service.dart';
import '../services/pro_service.dart';
import '../services/settings_service.dart';
import '../services/shifts_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/background_orb.dart';
import '../widgets/glass_parts.dart';

class AddShiftScreen extends StatefulWidget {
  const AddShiftScreen({
    super.key,
    required this.initialDate,
  });

  final DateTime initialDate;

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  final SettingsService _settingsService = SettingsService();
  final ShiftsService _shiftsService = ShiftsService();
  final ProService _proService = ProService();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isPro = false;


  static const List<String> _durationOptions = <String>[
    '8h',
    '10h',
    '12h',
  ];

  late DateTime _selectedDate;

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  String? _selectedShiftDuration;

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _productionNameController =
  TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _transportController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _overtimeRateController =
  TextEditingController();

  bool _addToDeviceCalendar = false;
  bool _isLoadingSettings = true;
  bool _ignoreFirst15MinOfFirstOtHour = true;

  AppSettings _settings = AppSettings.defaults();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _loadSettingsAndShift();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBannerIfNeeded();
    });
  }

  Future<void> _loadBannerIfNeeded() async {
    final isPro = await _proService.isPro();

    if (!mounted) return;

    if (isPro) {
      setState(() {
        _isPro = true;
        _isBannerLoaded = false;
      });
      return;
    }

    await AdService.instance.warmUpAfterFirstFrame();

    if (!mounted) return;

    final banner = await AdService.instance.createAdaptiveBanner(
      context: context,
    );

    if (!mounted) return;

    if (banner != null) {
      setState(() {
        _bannerAd = banner;
        _isBannerLoaded = true;
        _isPro = false;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _projectNameController.dispose();
    _productionNameController.dispose();
    _rateController.dispose();
    _transportController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _overtimeRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndShift() async {
    final loaded = await _settingsService.loadSettings();
    final existingShift = await _shiftsService.getShift(_selectedDate);

    if (existingShift != null) {
      _selectedShiftDuration = existingShift.shiftDuration.isEmpty
          ? null
          : existingShift.shiftDuration;
      _projectNameController.text = existingShift.projectName;
      _productionNameController.text = existingShift.productionName;
      _rateController.text = _numberText(existingShift.baseRate);
      _transportController.text = _numberText(existingShift.transportExpense);
      _overtimeRateController.text = _numberText(existingShift.overtimeRate);
      _locationController.text = existingShift.location;
      _notesController.text = existingShift.notes;
      _ignoreFirst15MinOfFirstOtHour =
          existingShift.ignoreFirst15MinOfFirstOtHour;

      _startTime = _parseStoredTime(
        existingShift.startTime,
        fallback: TimeOfDay(
          hour: loaded.defaultStartHour,
          minute: loaded.defaultStartMinute,
        ),
      );
      _endTime = _parseStoredTime(
        existingShift.endTime,
        fallback: TimeOfDay(
          hour: loaded.defaultEndHour,
          minute: loaded.defaultEndMinute,
        ),
      );
    } else {
      _selectedShiftDuration = null;
      _projectNameController.text = '';
      _productionNameController.text = '';
      _rateController.text = _numberText(loaded.defaultBaseRate);
      _transportController.text = '0';
      _overtimeRateController.text = _numberText(loaded.defaultOvertimeRate);
      _startTime = TimeOfDay(
        hour: loaded.defaultStartHour,
        minute: loaded.defaultStartMinute,
      );
      _endTime = TimeOfDay(
        hour: loaded.defaultEndHour,
        minute: loaded.defaultEndMinute,
      );
      _ignoreFirst15MinOfFirstOtHour = loaded.ignoreFirst15MinOfFirstOtHour;
    }

    _addToDeviceCalendar = loaded.addToCalendarByDefault;

    if (!mounted) return;

    setState(() {
      _settings = loaded;
      _isLoadingSettings = false;
    });
  }

  TimeOfDay _parseStoredTime(String value, {required TimeOfDay fallback}) {
    final parts = value.split(':');
    if (parts.length != 2) return fallback;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return fallback;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return fallback;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _numberText(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final DateTime now = DateHelpers.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8EA3FF),
              secondary: Color(0xFFFFC264),
              surface: Color(0xFF141922),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickStartTime() async {
    final l10n = AppLocalizations.of(context)!;
    final TimeOfDay? picked = await showGlassTimePicker(
      context: context,
      initialTime: _startTime,
      title: l10n.selectStartTime,
    );

    if (picked == null) return;

    setState(() {
      _startTime = picked;
    });
  }

  Future<void> _pickEndTime() async {
    final l10n = AppLocalizations.of(context)!;
    final TimeOfDay? picked = await showGlassTimePicker(
      context: context,
      initialTime: _endTime,
      title: l10n.selectEndTime,
    );

    if (picked == null) return;

    setState(() {
      _endTime = picked;
    });
  }

  double _parseNumber(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  int _durationHours() {
    if (_selectedShiftDuration == null || _selectedShiftDuration!.isEmpty) {
      return 0;
    }
    return int.tryParse(
      _selectedShiftDuration!.replaceAll('h', '').trim(),
    ) ??
        0;
  }

  int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  String _formatMinutesAsTime(int totalMinutes, {required bool use24Hour}) {
    int normalized = totalMinutes % 1440;
    if (normalized < 0) normalized += 1440;

    final int hour = normalized ~/ 60;
    final int minute = normalized % 60;

    return DateHelpers.formatTimeOfDay(
      hour,
      minute,
      use24HourFormat: use24Hour,
    );
  }

  int get _plannedEndMinutes {
    final durationHours = _durationHours();
    return _toMinutes(_startTime) + (durationHours * 60);
  }

  int get _actualEndAbsoluteMinutes {
    final start = _toMinutes(_startTime);
    int end = _toMinutes(_endTime);
    if (end < start) {
      end += 1440;
    }
    return end;
  }

  int get _overtimeMinutes {
    final durationHours = _durationHours();
    if (durationHours <= 0) return 0;

    final diff = _actualEndAbsoluteMinutes - _plannedEndMinutes;
    return diff > 0 ? diff : 0;
  }

  double get _calculatedOvertimeHours {
    final diff = _overtimeMinutes;

    if (_ignoreFirst15MinOfFirstOtHour) {
      if (diff <= 15) return 0;
      return math.max(1, (diff / 60).ceil()).toDouble();
    }

    if (diff <= 0) return 0;
    return (diff / 60).ceil().toDouble();
  }

  double get _overtimeTotal {
    return _calculatedOvertimeHours * _parseNumber(_overtimeRateController.text);
  }

  double get _baseTotal => _parseNumber(_rateController.text);

  double get _transportTotal => _parseNumber(_transportController.text);

  double get _grandTotal => _baseTotal + _overtimeTotal + _transportTotal;

  Future<void> _saveShift() async {
    final calculatedOtHours = _calculatedOvertimeHours;

    final shift = ShiftEntry(
      date: _selectedDate,
      startTime:
      '${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}',
      endTime:
      '${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}',
      shiftDuration: _selectedShiftDuration ?? '',
      projectName: _projectNameController.text.trim(),
      productionName: _productionNameController.text.trim(),
      baseRate: _baseTotal,
      overtimeHours: calculatedOtHours,
      overtimeRate: _parseNumber(_overtimeRateController.text),
      transportExpense: _transportTotal,
      location: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      isOvertime: calculatedOtHours > 0,
      ignoreFirst15MinOfFirstOtHour: _ignoreFirst15MinOfFirstOtHour,
      paymentStatus: PaymentStatus.unpaid,
      isDayOff: false,
    );

    await _shiftsService.saveShift(shift);

    if (!mounted) return;

    await AdService.instance.registerActionAndMaybeShow(
      onContinue: () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingSettings) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E13),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final overtimeTotal = _overtimeTotal;
    final transportTotal = _transportTotal;
    final grandTotal = _grandTotal;
    final currencyCode = _settings.currencyCode;
    final currencySymbol = DateHelpers.currencySymbol(currencyCode);
    final plannedEndLabel = _durationHours() > 0
        ? _formatMinutesAsTime(
      _plannedEndMinutes,
      use24Hour: _settings.use24HourFormat,
    )
        : '—';
    final overtimeHoursLabel = _calculatedOvertimeHours == 0
        ? '0h'
        : '${_calculatedOvertimeHours.toStringAsFixed(0)}h';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF070A10),
              Color(0xFF101620),
              Color(0xFF0C1017),
            ],
          ),
        ),
        child: Stack(
          children: <Widget>[
            const BackgroundOrb(
              size: 220,
              top: -80,
              right: -50,
              color: Color(0x338EA3FF),
            ),
            const BackgroundOrb(
              size: 180,
              bottom: -70,
              left: -20,
              color: Color(0x22FFC264),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: <Widget>[
                        TopGlassButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.addShiftTitle,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                DateHelpers.formatShortDate(_selectedDate),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.62),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      physics: const BouncingScrollPhysics(),
                      children: <Widget>[
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.dateAndTime,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _ActionField(
                                label: l10n.dateLabel,
                                value: DateHelpers.formatShortDate(_selectedDate),
                                icon: Icons.calendar_today_outlined,
                                onTap: _pickDate,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _ActionField(
                                      label: l10n.startLabel,
                                      value: DateHelpers.formatTimeOfDay(
                                        _startTime.hour,
                                        _startTime.minute,
                                        use24HourFormat:
                                        _settings.use24HourFormat,
                                      ),
                                      icon: Icons.login_rounded,
                                      onTap: _pickStartTime,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ActionField(
                                      label: l10n.endLabel,
                                      value: DateHelpers.formatTimeOfDay(
                                        _endTime.hour,
                                        _endTime.minute,
                                        use24HourFormat:
                                        _settings.use24HourFormat,
                                      ),
                                      icon: Icons.logout_rounded,
                                      onTap: _pickEndTime,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.projectInfo,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _DropdownField(
                                label: l10n.shiftDuration,
                                value: _selectedShiftDuration,
                                items: _durationOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedShiftDuration = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _GlassTextField(
                                controller: _projectNameController,
                                label: l10n.projectName,
                                hint: l10n.projectHint,
                              ),
                              const SizedBox(height: 12),
                              _GlassTextField(
                                controller: _productionNameController,
                                label: l10n.productionName,
                                hint: l10n.productionHint,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.shiftDetails,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _GlassTextField(
                                controller: _rateController,
                                label: l10n.baseRateAmount,
                                hint:
                                '${l10n.examplePrefix} ${currencySymbol}240',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              _GlassTextField(
                                controller: _transportController,
                                label: l10n.transportExpense,
                                hint:
                                '${l10n.examplePrefix} ${currencySymbol}25',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              _GlassTextField(
                                controller: _locationController,
                                label: l10n.locationLabel,
                                hint: l10n.locationHint,
                              ),
                              const SizedBox(height: 12),
                              _GlassTextField(
                                controller: _notesController,
                                label: l10n.notesLabel,
                                hint: l10n.notesHint,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.overtimeTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _GlassTextField(
                                controller: _overtimeRateController,
                                label: l10n.overtimeRate,
                                hint:
                                '${l10n.examplePrefix} ${currencySymbol}40',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              _SwitchRow(
                                title: l10n.ignoreFirst15,
                                value: _ignoreFirst15MinOfFirstOtHour,
                                onChanged: (value) {
                                  setState(() {
                                    _ignoreFirst15MinOfFirstOtHour = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _InfoPill(
                                label: l10n.plannedEnd,
                                value: plannedEndLabel,
                              ),
                              const SizedBox(height: 10),
                              _InfoPill(
                                label: l10n.calculatedOt,
                                value: overtimeHoursLabel,
                              ),
                              const SizedBox(height: 10),
                              GlassShadowWrapper(
                                radius: 18,
                                blur: 16,
                                opacity: 0.10,
                                color: const Color(0xFFFFC264),
                                child: GlassContainer(
                                  blur: 18,
                                  borderRadius: BorderRadius.circular(18),
                                  color:
                                  const Color(0xFFFFC264).withOpacity(0.08),
                                  border: Border.all(
                                    color: const Color(0xFFFFC264)
                                        .withOpacity(0.18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFFFC264)
                                                .withOpacity(0.12),
                                          ),
                                          child: const Icon(
                                            Icons.bolt_rounded,
                                            size: 16,
                                            color: Color(0xFFFFC264),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                l10n.overtimeTotal,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.56),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                DateHelpers.formatMoney(
                                                  overtimeTotal,
                                                  currencyCode: currencyCode,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFFFC264),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _SwitchRow(
                                title: l10n.addToCalendar,
                                value: _addToDeviceCalendar,
                                onChanged: (value) {
                                  setState(() {
                                    _addToDeviceCalendar = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            children: <Widget>[
                              _MoneyLine(
                                label: l10n.baseLabel,
                                value: DateHelpers.formatMoney(
                                  _baseTotal,
                                  currencyCode: currencyCode,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MoneyLine(
                                label: l10n.overtimeLabel,
                                value: DateHelpers.formatMoney(
                                  overtimeTotal,
                                  currencyCode: currencyCode,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MoneyLine(
                                label: l10n.transportLabel,
                                value: DateHelpers.formatMoney(
                                  _transportTotal,
                                  currencyCode: currencyCode,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),
                              const SizedBox(height: 12),
                              _MoneyLine(
                                label: l10n.estimatedTotal,
                                value: DateHelpers.formatMoney(
                                  grandTotal,
                                  currencyCode: currencyCode,
                                ),
                                isPrimary: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GlassShadowWrapper(
                          radius: 22,
                          blur: 24,
                          opacity: 0.16,
                          color: const Color(0xFF8EA3FF),
                          child: SizedBox(
                            width: double.infinity,
                            child: GlassContainer(
                              blur: 20,
                              borderRadius: BorderRadius.circular(22),
                              color: const Color(0xFF8EA3FF).withOpacity(0.24),
                              border: Border.all(
                                color: const Color(0xFFB9C5FF)
                                    .withOpacity(0.32),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: _saveShift,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 18,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          l10n.saveShift,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 18,
      blur: 16,
      opacity: 0.10,
      child: GlassContainer(
        blur: 18,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: const Color(0xFF141922),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.58)),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            iconEnabledColor: Colors.white,
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 18,
      blur: 16,
      opacity: 0.10,
      child: GlassContainer(
        blur: 18,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 18,
      blur: 16,
      opacity: 0.10,
      child: GlassContainer(
        blur: 18,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 18, color: const Color(0xFF8EA3FF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 18,
      blur: 16,
      opacity: 0.10,
      child: GlassContainer(
        blur: 18,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.58)),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.32)),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassShadowWrapper(
      radius: 18,
      blur: 16,
      opacity: 0.10,
      child: GlassContainer(
        blur: 18,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF8EA3FF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    required this.label,
    required this.value,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(isPrimary ? 0.92 : 0.62),
            fontSize: isPrimary ? 15 : 14,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? Colors.white : Colors.white.withOpacity(0.86),
            fontSize: isPrimary ? 22 : 15,
            fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}