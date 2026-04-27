import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

import '../services/backup_service.dart';
import '../services/pro_service.dart';
import '../services/shifts_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../locale_controller.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/background_orb.dart';
import '../widgets/glass_parts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.localeController,
  });

  final LocaleController localeController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final ProService _proService = ProService();

  bool _isLoading = true;
  bool _isPro = false;
  late AppSettings _settings;

  late TextEditingController _baseRateController;
  late TextEditingController _overtimeRateController;
  late TextEditingController _overtimeHoursController;

  final List<String> _languages = <String>[
    'system',
    'en',
    'uk',
  ];

  final List<String> _currencies = <String>[
    'USD',
    'EUR',
    'UAH',
    'GBP',
    'PLN',
    'CAD',
  ];

  @override
  void initState() {
    super.initState();
    _settings = AppSettings.defaults();
    _baseRateController = TextEditingController();
    _overtimeRateController = TextEditingController();
    _overtimeHoursController = TextEditingController();
    _load();
    _refreshPro();
  }

  Future<void> _refreshPro() async {
    final isPro = await _proService.isPro();

    if (!mounted) return;

    setState(() {
      _isPro = isPro;
    });
  }

  Future<void> _load() async {
    final loaded = await _settingsService.loadSettings();
    final isPro = await _proService.isPro();

    _baseRateController.text = _numberText(loaded.defaultBaseRate);
    _overtimeRateController.text = _numberText(loaded.defaultOvertimeRate);
    _overtimeHoursController.text = _numberText(loaded.defaultOvertimeHours);

    if (!mounted) return;

    setState(() {
      _settings = loaded;
      _isPro = isPro;
      _isLoading = false;
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

  String _languageLabel(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;

    switch (code) {
      case 'system':
        return l10n.languageSystem;
      case 'en':
        return l10n.languageEnglish;
      case 'uk':
        return l10n.languageUkrainian;
      default:
        return code;
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    final updated = _settings.copyWith(
      defaultBaseRate: _parseNumber(
        _baseRateController.text,
        _settings.defaultBaseRate,
      ),
      defaultOvertimeRate: _parseNumber(
        _overtimeRateController.text,
        _settings.defaultOvertimeRate,
      ),
      defaultOvertimeHours: _parseNumber(
        _overtimeHoursController.text,
        _settings.defaultOvertimeHours,
      ),
    );

    await _settingsService.saveSettings(updated);

    if (!mounted) return;

    setState(() {
      _settings = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsSaved),
      ),
    );
  }

  Future<void> _backupNow() async {
    final shiftsService = ShiftsService();
    final data = await shiftsService.getAllShifts();

    final map = <String, dynamic>{};
    data.forEach((key, value) {
      map[key] = value.toMap();
    });

    final backupService = BackupService();
    await backupService.backupNow(map);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup saved to Documents')),
    );
  }

  Future<void> _importBackup() async {
    try {
      final backupService = BackupService();
      final Map<String, dynamic>? data =
      await backupService.importBackupFromFile();

      if (data == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup file was not selected')),
        );
        return;
      }

      final dynamic shiftsService = ShiftsService();

      await shiftsService.clearAll();

      for (final entry in data.entries) {
        await shiftsService.saveShiftFromMap(entry.key, entry.value);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  Future<void> _buy() async {
    try {
      await _proService.buyPro();

      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final updated = await _proService.isPro();

        if (!mounted) return;

        if (updated) {
          setState(() {
            _isPro = true;
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

  @override
  void dispose() {
    _baseRateController.dispose();
    _overtimeRateController.dispose();
    _overtimeHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({
    required bool isStart,
  }) async {
    final initial = TimeOfDay(
      hour: isStart ? _settings.defaultStartHour : _settings.defaultEndHour,
      minute:
      isStart ? _settings.defaultStartMinute : _settings.defaultEndMinute,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
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
      _settings = isStart
          ? _settings.copyWith(
        defaultStartHour: picked.hour,
        defaultStartMinute: picked.minute,
      )
          : _settings.copyWith(
        defaultEndHour: picked.hour,
        defaultEndMinute: picked.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0E13),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currencySymbol = DateHelpers.currencySymbol(_settings.currencyCode);

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
                                l10n.settings,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                l10n.settingsSubtitle,
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
                                'Ads & backup',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _isPro
                                    ? 'Ads are disabled. Auto backup is enabled.'
                                    : 'Turn off ads and enable auto backup.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.62),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SoftGlassButton(
                                label: _isPro ? 'Ads disabled' : 'Turn off ads',
                                icon: Icons.shield_moon_rounded,
                                onTap: _buy,
                              ),

                              const SizedBox(height: 10),

                              SoftGlassButton(
                                label: 'Restore purchases',
                                icon: Icons.restore_rounded,
                                onTap: () async {
                                  try {
                                    await _proService.restore();

                                    for (int i = 0; i < 10; i++) {
                                      await Future.delayed(const Duration(milliseconds: 500));
                                      final updated = await _proService.isPro();

                                      if (!mounted) return;

                                      if (updated) {
                                        setState(() {
                                          _isPro = true;
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Purchase restored')),
                                        );
                                        return;
                                      }
                                    }

                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No purchases to restore'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
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
                                l10n.language,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _DropdownField(
                                label: l10n.appLanguage,
                                value: _settings.localeCode,
                                items: _languages,
                                itemLabelBuilder: (code) =>
                                    _languageLabel(context, code),
                                onChanged: (value) async {
                                  if (value == null) return;

                                  setState(() {
                                    _settings =
                                        _settings.copyWith(localeCode: value);
                                  });

                                  await widget.localeController
                                      .setLocaleCode(value);
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
                                l10n.currency,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _DropdownField(
                                label: l10n.workingCurrency,
                                value: _settings.currencyCode,
                                items: _currencies,
                                itemLabelBuilder: (code) =>
                                '$code · ${DateHelpers.currencySymbol(code)}',
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _settings =
                                        _settings.copyWith(currencyCode: value);
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
                                l10n.calendar,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _SwitchRow(
                                title: l10n.showAmounts,
                                value: _settings.showAmountsOnCalendar,
                                onChanged: (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      showAmountsOnCalendar: value,
                                    );
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
                                l10n.overtime,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _SwitchRow(
                                title: l10n.ignoreFirst15,
                                value: _settings.ignoreFirst15MinOfFirstOtHour,
                                onChanged: (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      ignoreFirst15MinOfFirstOtHour: value,
                                    );
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
                                l10n.time,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _SwitchRow(
                                title: l10n.use24h,
                                value: _settings.use24HourFormat,
                                onChanged: (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      use24HourFormat: value,
                                    );
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _ActionField(
                                      label: l10n.defaultStart,
                                      value: DateHelpers.formatTimeOfDay(
                                        _settings.defaultStartHour,
                                        _settings.defaultStartMinute,
                                        use24HourFormat:
                                        _settings.use24HourFormat,
                                      ),
                                      icon: Icons.login_rounded,
                                      onTap: () => _pickTime(isStart: true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _ActionField(
                                      label: l10n.defaultEnd,
                                      value: DateHelpers.formatTimeOfDay(
                                        _settings.defaultEndHour,
                                        _settings.defaultEndMinute,
                                        use24HourFormat:
                                        _settings.use24HourFormat,
                                      ),
                                      icon: Icons.logout_rounded,
                                      onTap: () => _pickTime(isStart: false),
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
                                l10n.defaultRates,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _GlassTextField(
                                controller: _baseRateController,
                                label: l10n.defaultBaseRate,
                                hint:
                                '${l10n.examplePrefix} ${currencySymbol}240',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _GlassTextField(
                                controller: _overtimeRateController,
                                label: l10n.defaultOvertimeRate,
                                hint:
                                '${l10n.examplePrefix} ${currencySymbol}40',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _GlassTextField(
                                controller: _overtimeHoursController,
                                label: l10n.defaultOvertimeHours,
                                hint: '${l10n.examplePrefix} 2',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            children: <Widget>[
                              _SwitchRow(
                                title: l10n.addToDeviceCalendarByDefault,
                                value: _settings.addToCalendarByDefault,
                                onChanged: (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      addToCalendarByDefault: value,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_isPro) ...<Widget>[
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Backup',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withOpacity(0.92),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Backup file: Documents/shiftnote_backup.json',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.62),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: SoftGlassButton(
                                        label: 'Backup',
                                        icon: Icons.save_rounded,
                                        onTap: _backupNow,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: SoftGlassButton(
                                        label: 'Import',
                                        icon: Icons.upload_rounded,
                                        onTap: _importBackup,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
                              color:
                              const Color(0xFF8EA3FF).withOpacity(0.24),
                              border: Border.all(
                                color:
                                const Color(0xFFB9C5FF).withOpacity(0.32),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(22),
                                  onTap: _save,
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
                                          l10n.saveSettings,
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
    required this.itemLabelBuilder,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String item) itemLabelBuilder;

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
                child: Text(itemLabelBuilder(item)),
              );
            }).toList(),
            onChanged: onChanged,
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
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

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