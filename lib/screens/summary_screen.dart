import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_settings.dart';
import '../models/member_report.dart';
import '../models/shift_entry.dart';
import '../services/ad_service.dart';
import '../services/pro_service.dart';
import '../services/settings_service.dart';
import '../services/shifts_service.dart';
import '../services/team_reports_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/background_orb.dart';
import '../widgets/glass_parts.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.selectedDates});
  final List<DateTime> selectedDates;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final ShiftsService _shiftsService = ShiftsService();
  final SettingsService _settingsService = SettingsService();
  final TeamReportsService _teamReportsService = TeamReportsService();
  final ProService _proService = ProService();

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool _isPro = false;
  bool _isLoading = true;
  AppSettings _settings = AppSettings.defaults();
  List<ShiftEntry> _shifts = <ShiftEntry>[];
  List<MemberReport> _memberReports = <MemberReport>[];

  @override
  void initState() {
    super.initState();
    _load();
    _refreshPro();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isPro = await _proService.isPro();
      if (isPro) return;
      await AdService.instance.warmUpAfterFirstFrame();
      if (!mounted) return;
      final banner = await AdService.instance.createAdaptiveBanner(context: context);
      if (!mounted || banner == null) return;
      setState(() {
        _bannerAd = banner;
        _isBannerLoaded = true;
      });
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
      if (isPro) _isBannerLoaded = false;
    });
  }

  Future<void> _load() async {
    final settings = await _settingsService.loadSettings();
    final dates = List<DateTime>.from(widget.selectedDates)..sort((a, b) => a.compareTo(b));
    final loaded = <ShiftEntry>[];
    for (final date in dates) {
      final shift = await _shiftsService.getShift(date);
      if (shift != null && !shift.isDayOff) loaded.add(shift);
    }
    final reports = await _teamReportsService.getReportsByProject(_titleFromShifts(loaded, (s) => s.projectName, 'Mixed projects'));
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _shifts = loaded;
      _memberReports = reports;
      _isLoading = false;
    });
  }

  String _titleFromShifts(List<ShiftEntry> shifts, String Function(ShiftEntry) pick, String mixedLabel) {
    final values = shifts.map(pick).map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList();
    if (values.isEmpty) return '—';
    return values.length == 1 ? values.first : mixedLabel;
  }

  String get _projectTitle => _titleFromShifts(_shifts, (s) => s.projectName, 'Mixed projects');
  String get _productionTitle => _titleFromShifts(_shifts, (s) => s.productionName, 'Mixed productions');
  double get _myTotal => _shifts.fold(0.0, (sum, s) => sum + s.total);
  double get _teamTotal => _memberReports.fold(0.0, (sum, r) => sum + r.total);
  double get _grandTotal => _myTotal + _teamTotal;
  double get _shortRestTotal => _shifts.fold(0.0, (sum, s) => sum + s.shortRestTotal);
  double get _extraServicesTotal => _shifts.fold(0.0, (sum, s) => sum + s.extraServiceAmount);

  String _money(double value) => DateHelpers.formatMoney(value, currencyCode: _settings.currencyCode);

  String _statusTitle(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid: return 'Unpaid';
      case PaymentStatus.sent: return 'Sent';
      case PaymentStatus.paid: return 'Paid';
    }
  }

  Color _statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid: return const Color(0xFFFF6B6B);
      case PaymentStatus.sent: return const Color(0xFFFFC264);
      case PaymentStatus.paid: return const Color(0xFF78E08F);
    }
  }

  Future<void> _setStatuses(PaymentStatus status) async {
    await _shiftsService.updateShiftStatuses(_shifts.map((e) => e.date).toList(), status);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked as ${_statusTitle(status)}')));
  }

  Future<String?> _askParticipantName() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ваше имя в отчёте'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Напр. Дилан')),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Экспортировать')),
        ],
      ),
    );
    controller.dispose();
    return value?.trim().isEmpty == true ? null : value;
  }

  Future<void> _exportMyReport() async {
    if (_shifts.isEmpty) return;
    final name = await _askParticipantName();
    if (name == null) return;
    final file = await _teamReportsService.exportMyReport(participantName: name, shifts: _shifts);
    if (!mounted) return;
    await Share.shareXFiles(<XFile>[XFile(file.path)], subject: 'ShiftNote report: $_projectTitle');
  }

  Future<void> _importMemberReport() async {
    try {
      final report = await _teamReportsService.pickReportFile();
      if (report == null) return;
      if (_projectTitle != '—' && _projectTitle != 'Mixed projects' && report.projectName.trim().toLowerCase() != _projectTitle.trim().toLowerCase()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Отчёт относится к другому проекту: ${report.projectName}')));
        return;
      }
      final existing = _memberReports.where((r) => r.matchKey == report.matchKey).toList();
      if (existing.isNotEmpty) {
        if (!mounted) return;
        final replace = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Отчёт уже импортирован'),
            content: Text('Заменить отчёт участника ${report.participantName} за этот период?'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Заменить')),
            ],
          ),
        );
        if (replace != true) return;
      }
      await _teamReportsService.saveImportedReport(report);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Импортирован отчёт: ${report.participantName}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось импортировать отчёт: $e')));
    }
  }

  Future<void> _shareSummary() async {
    final buffer = StringBuffer()
      ..writeln('Payment summary')
      ..writeln('Project: $_projectTitle')
      ..writeln('Production: $_productionTitle')
      ..writeln();
    buffer.writeln('MY SHIFTS');
    for (final shift in _shifts) {
      buffer.writeln('${DateHelpers.formatShortDate(shift.date)} | ${shift.timeRangeLabel} | Total: ${_money(shift.total)}');
      if (shift.effectiveOvertimeHours > 0) buffer.writeln('  OT: ${shift.effectiveOvertimeHours} h / ${_money(shift.regularOvertimeTotal)}');
      if (shift.shortRestHours > 0) buffer.writeln('  Short rest: ${shift.shortRestHours} h / ${_money(shift.shortRestTotal)}');
      if (shift.transportExpense > 0) buffer.writeln('  Transport: ${_money(shift.transportExpense)}');
      if (shift.extraServiceAmount > 0) buffer.writeln('  ${shift.extraServiceTitle.isEmpty ? 'Extra service' : shift.extraServiceTitle}: ${_money(shift.extraServiceAmount)}');
    }
    buffer.writeln('My total: ${_money(_myTotal)}');
    for (final report in _memberReports) {
      buffer.writeln();
      buffer.writeln('${report.participantName.toUpperCase()} (${report.shifts.length} shifts)');
      for (final shift in report.shifts) {
        buffer.writeln('${DateHelpers.formatShortDate(shift.date)} | ${shift.timeRangeLabel} | Total: ${_money(shift.total)}');
      }
      buffer.writeln('${report.participantName} total: ${_money(report.total)}');
    }
    buffer.writeln();
    buffer.writeln('GRAND TOTAL: ${_money(_grandTotal)}');
    await Share.share(buffer.toString(), subject: 'Payment summary: $_projectTitle');
    await _setStatuses(PaymentStatus.sent);
    await AdService.instance.registerActionAndMaybeShow(onContinue: () {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF070A10), Color(0xFF101620), Color(0xFF0C1017)]),
        ),
        child: Stack(
          children: <Widget>[
            const BackgroundOrb(size: 220, top: -80, right: -50, color: Color(0x338EA3FF)),
            const BackgroundOrb(size: 180, bottom: -70, left: -20, color: Color(0x22FFC264)),
            SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Row(children: <Widget>[
                            TopGlassButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                              const Text('Payment summary', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                              Text('${widget.selectedDates.length} days · ${_memberReports.length} imported reports', style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 14)),
                            ])),
                          ]),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: <Widget>[
                              GlassCard(child: Column(children: <Widget>[
                                _InfoRow(label: 'Project', value: _projectTitle),
                                _InfoRow(label: 'Production', value: _productionTitle),
                                _InfoRow(label: 'My shifts', value: '${_shifts.length}'),
                                _InfoRow(label: 'Imported participants', value: '${_memberReports.length}', removeBottomPadding: true),
                              ])),
                              const SizedBox(height: 16),
                              if (_memberReports.isNotEmpty) ...<Widget>[
                                const Text('Команда', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 10),
                                ..._memberReports.map((report) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GlassCard(child: Column(children: <Widget>[
                                    _InfoRow(label: report.participantName, value: _money(report.total)),
                                    _InfoRow(label: 'Смен', value: '${report.shifts.length}', removeBottomPadding: true),
                                  ])),
                                )),
                                const SizedBox(height: 6),
                              ],
                              ..._shifts.map((shift) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                                  Row(children: <Widget>[
                                    Expanded(child: Text(DateHelpers.formatShortDate(shift.date))),
                                    Text(_statusTitle(shift.paymentStatus), style: TextStyle(color: _statusColor(shift.paymentStatus))),
                                  ]),
                                  const SizedBox(height: 12),
                                  _InfoRow(label: 'Hours', value: shift.timeRangeLabel),
                                  _InfoRow(label: 'Base', value: _money(shift.baseRate)),
                                  _InfoRow(label: 'OT', value: _money(shift.regularOvertimeTotal)),
                                  if (shift.shortRestHours > 0) _InfoRow(label: 'Недосып (${shift.shortRestHours} h)', value: _money(shift.shortRestTotal)),
                                  _InfoRow(label: 'Transport', value: _money(shift.transportExpense)),
                                  if (shift.extraServiceAmount > 0) _InfoRow(label: shift.extraServiceTitle.isEmpty ? 'Допуслуга' : shift.extraServiceTitle, value: _money(shift.extraServiceAmount)),
                                  _InfoRow(label: 'Total', value: _money(shift.total), removeBottomPadding: true),
                                ])),
                              )),
                              GlassCard(child: Column(children: <Widget>[
                                _MoneyLine(label: 'My total', value: _money(_myTotal)),
                                const SizedBox(height: 10),
                                if (_shortRestTotal > 0) ...<Widget>[
                                  _MoneyLine(label: 'В т.ч. недосып', value: _money(_shortRestTotal)),
                                  const SizedBox(height: 10),
                                ],
                                if (_extraServicesTotal > 0) ...<Widget>[
                                  _MoneyLine(label: 'В т.ч. допуслуги', value: _money(_extraServicesTotal)),
                                  const SizedBox(height: 10),
                                ],
                                _MoneyLine(label: 'Imported team total', value: _money(_teamTotal)),
                                const SizedBox(height: 12),
                                Container(height: 1, color: Colors.white.withOpacity(0.08)),
                                const SizedBox(height: 12),
                                _MoneyLine(label: 'Grand total', value: _money(_grandTotal), isPrimary: true),
                              ])),
                              const SizedBox(height: 16),
                              Row(children: <Widget>[
                                Expanded(child: SoftGlassButton(label: 'Экспорт моего отчёта', icon: Icons.upload_file_rounded, onTap: _exportMyReport)),
                                const SizedBox(width: 10),
                                Expanded(child: SoftGlassButton(label: 'Импорт участника', icon: Icons.download_rounded, onTap: _importMemberReport)),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: <Widget>[
                                Expanded(child: SoftGlassButton(label: 'Share total', icon: Icons.share_rounded, onTap: _shareSummary)),
                                const SizedBox(width: 10),
                                Expanded(child: SoftGlassButton(label: 'Paid', icon: Icons.check_circle_rounded, onTap: () => _setStatuses(PaymentStatus.paid))),
                              ]),
                            ],
                          ),
                        ),
                        if (!_isPro && _isBannerLoaded && _bannerAd != null)
                          SafeArea(top: false, child: Padding(padding: const EdgeInsets.only(bottom: 6), child: SizedBox(width: _bannerAd!.size.width.toDouble(), height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!)))),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.removeBottomPadding = false});
  final String label;
  final String value;
  final bool removeBottomPadding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: removeBottomPadding ? 0 : 10),
        child: Row(children: <Widget>[Expanded(child: Text(label)), const SizedBox(width: 8), Text(value)]),
      );
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.label, required this.value, this.isPrimary = false});
  final String label;
  final String value;
  final bool isPrimary;
  @override
  Widget build(BuildContext context) => Row(children: <Widget>[
        Expanded(child: Text(label)),
        Text(value, style: TextStyle(fontSize: isPrimary ? 22 : 15, fontWeight: FontWeight.w800)),
      ]);
}
