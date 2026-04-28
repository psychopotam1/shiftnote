import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/shift_entry.dart';
import '../services/ad_service.dart';
import '../services/pro_service.dart';
import '../services/settings_service.dart';
import '../services/shifts_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/background_orb.dart';
import '../widgets/glass_parts.dart';

class BatchTemplateScreen extends StatefulWidget {
  const BatchTemplateScreen({
    super.key,
    required this.selectedDates,
  });

  final List<DateTime> selectedDates;

  @override
  State<BatchTemplateScreen> createState() => _BatchTemplateScreenState();
}

class _BatchTemplateScreenState extends State<BatchTemplateScreen> {
  final ShiftsService _shiftsService = ShiftsService();
  final SettingsService _settingsService = SettingsService();
  final ProService _proService = ProService();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isPro = false;

  static const List<String> _durationOptions = <String>[
    '8h',
    '10h',
    '12h',
  ];

  bool _isLoading = true;
  bool _ignoreFirst15 = true;
  AppSettings _settings = AppSettings.defaults();

  String? _selectedShiftDuration;

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _productionNameController =
  TextEditingController();
  final TextEditingController _baseRateController = TextEditingController();
  final TextEditingController _overtimeRateController =
  TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _loadBanner();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _projectNameController.dispose();
    _productionNameController.dispose();
    _baseRateController.dispose();
    _overtimeRateController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadBanner() async {
    final isPro = await _proService.isPro();

    if (!mounted) return;

    setState(() {
      _isPro = isPro;
    });

    if (isPro) {
      _bannerAd?.dispose();
      _bannerAd = null;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await AdService.instance.warmUpAfterFirstFrame();

      final banner = await AdService.instance.createAdaptiveBanner(
        context: context,
      );

      if (!mounted) {
        banner?.dispose();
        return;
      }

      setState(() {
        _bannerAd = banner;
        _isBannerLoaded = banner != null;
      });
    });
  }

  String _numberText(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  double _parseNumber(String value, double fallback) {
    final normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? fallback;
  }

  Future<void> _loadInitial() async {
    final settings = await _settingsService.loadSettings();

    ShiftEntry? seedShift;
    for (final date in widget.selectedDates) {
      final existing = await _shiftsService.getShift(date);
      if (existing != null && !existing.isDayOff) {
        seedShift = existing;
        break;
      }
    }

    _selectedShiftDuration =
    seedShift?.shiftDuration.isNotEmpty == true ? seedShift!.shiftDuration : null;
    _projectNameController.text = seedShift?.projectName ?? '';
    _productionNameController.text = seedShift?.productionName ?? '';
    _baseRateController.text = _numberText(
      seedShift?.baseRate ?? settings.defaultBaseRate,
    );
    _overtimeRateController.text = _numberText(
      seedShift?.overtimeRate ?? settings.defaultOvertimeRate,
    );
    _locationController.text = seedShift?.location ?? '';
    _notesController.text = seedShift?.notes ?? '';
    _ignoreFirst15 = seedShift?.ignoreFirst15MinOfFirstOtHour ??
        settings.ignoreFirst15MinOfFirstOtHour;

    if (!mounted) return;

    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _applyTemplate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedShiftDuration == null || _selectedShiftDuration!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.batchChooseShiftDurationFirst)),
      );
      return;
    }

    await _shiftsService.applyTemplateToDates(
      dates: widget.selectedDates,
      shiftDuration: _selectedShiftDuration!,
      projectName: _projectNameController.text,
      productionName: _productionNameController.text,
      baseRate: _parseNumber(
        _baseRateController.text,
        _settings.defaultBaseRate,
      ),
      overtimeRate: _parseNumber(
        _overtimeRateController.text,
        _settings.defaultOvertimeRate,
      ),
      location: _locationController.text,
      notes: _notesController.text,
      ignoreFirst15MinOfFirstOtHour: _ignoreFirst15,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = _settings.currencyCode;
    final currencySymbol = DateHelpers.currencySymbol(currencyCode);
    final showBanner = !_isPro && _isBannerLoaded && _bannerAd != null;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E13),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                                l10n.batchTemplateTitle,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                l10n.selectedDaysCount(widget.selectedDates.length),
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
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: <Widget>[
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.projectTemplate,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _TemplateDropdownField(
                                label: l10n.batchShiftDuration,
                                value: _selectedShiftDuration,
                                items: _durationOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedShiftDuration = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _TemplateTextField(
                                controller: _projectNameController,
                                label: l10n.batchProjectName,
                                hint: l10n.projectHint,
                              ),
                              const SizedBox(height: 12),
                              _TemplateTextField(
                                controller: _productionNameController,
                                label: l10n.batchProductionName,
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
                                l10n.rates,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _TemplateTextField(
                                controller: _baseRateController,
                                label: l10n.batchBaseRate,
                                hint: '${currencySymbol}240',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _TemplateTextField(
                                controller: _overtimeRateController,
                                label: l10n.batchOvertimeRate,
                                hint: '${currencySymbol}40',
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _TemplateSwitchRow(
                                title: l10n.ignoreFirst15,
                                value: _ignoreFirst15,
                                onChanged: (value) {
                                  setState(() {
                                    _ignoreFirst15 = value;
                                  });
                                },
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
                                l10n.optionalDetails,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _TemplateTextField(
                                controller: _locationController,
                                label: l10n.batchLocation,
                                hint: l10n.locationHint,
                              ),
                              const SizedBox(height: 12),
                              _TemplateTextField(
                                controller: _notesController,
                                label: l10n.batchNotes,
                                hint: l10n.notesHint,
                                maxLines: 4,
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
                            child: Material(
                              color: const Color(0xFF8EA3FF).withOpacity(0.22),
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: _applyTemplate,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      const Icon(
                                        Icons.playlist_add_check_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        l10n.applyToSelectedDays,
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
                      ],
                    ),
                  ),
                  if (showBanner)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
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

class _TemplateDropdownField extends StatelessWidget {
  const _TemplateDropdownField({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
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
    );
  }
}

class _TemplateTextField extends StatelessWidget {
  const _TemplateTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.58)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.32)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _TemplateSwitchRow extends StatelessWidget {
  const _TemplateSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
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
    );
  }
}
