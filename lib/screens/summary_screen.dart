import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_settings.dart';
import '../models/shift_entry.dart';
import '../services/ad_service.dart';
import '../services/settings_service.dart';
import '../services/shifts_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/background_orb.dart';
import '../widgets/glass_parts.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({
    super.key,
    required this.selectedDates,
  });

  final List<DateTime> selectedDates;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final ShiftsService _shiftsService = ShiftsService();
  final SettingsService _settingsService = SettingsService();

  bool _isLoading = true;
  AppSettings _settings = AppSettings.defaults();
  List<ShiftEntry> _shifts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _settingsService.loadSettings();

    final dates = List<DateTime>.from(widget.selectedDates)
      ..sort((a, b) => a.compareTo(b));

    final loaded = <ShiftEntry>[];

    for (final date in dates) {
      final shift = await _shiftsService.getShift(date);
      if (shift != null) {
        loaded.add(shift);
      }
    }

    if (!mounted) return;

    setState(() {
      _settings = settings;
      _shifts = loaded;
      _isLoading = false;
    });
  }

  double get _baseTotal => _shifts.fold(0.0, (sum, s) => sum + s.baseRate);

  double get _overtimeTotal =>
      _shifts.fold(0.0, (sum, s) => sum + s.overtimeTotal);

  double get _transportTotal =>
      _shifts.fold(0.0, (sum, s) => sum + s.transportExpense);

  double get _grandTotal => _shifts.fold(0.0, (sum, s) => sum + s.total);

  String _projectTitle() {
    final values = _shifts
        .map((e) => e.projectName.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (values.isEmpty) return '—';
    if (values.length == 1) return values.first;
    return 'Mixed projects';
  }

  String _productionTitle() {
    final values = _shifts
        .map((e) => e.productionName.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (values.isEmpty) return '—';
    if (values.length == 1) return values.first;
    return 'Mixed productions';
  }

  String _statusTitle(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.sent:
        return 'Sent';
      case PaymentStatus.paid:
        return 'Paid';
    }
  }

  Color _statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.unpaid:
        return const Color(0xFFFF6B6B);
      case PaymentStatus.sent:
        return const Color(0xFFFFC264);
      case PaymentStatus.paid:
        return const Color(0xFF78E08F);
    }
  }

  Future<void> _setStatuses(PaymentStatus status) async {
    final dates = _shifts.map((e) => e.date).toList();

    await _shiftsService.updateShiftStatuses(dates, status);
    await _load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked as ${_statusTitle(status)}'),
      ),
    );
  }

  Future<void> _shareSummary() async {
    final buffer = StringBuffer();

    buffer.writeln('Payment summary');
    buffer.writeln();
    buffer.writeln('Project: ${_projectTitle()}');
    buffer.writeln('Production: ${_productionTitle()}');
    buffer.writeln();

    for (final shift in _shifts) {
      buffer.writeln(DateHelpers.formatShortDate(shift.date));
      buffer.writeln('Status: ${_statusTitle(shift.paymentStatus)}');
      buffer.writeln('Hours: ${shift.startTime} - ${shift.endTime}');
      buffer.writeln('Duration: ${shift.shiftDuration}');
      buffer.writeln(
        'Base: ${DateHelpers.formatMoney(shift.baseRate, currencyCode: _settings.currencyCode)}',
      );
      buffer.writeln(
        'OT: ${DateHelpers.formatMoney(shift.overtimeTotal, currencyCode: _settings.currencyCode)}',
      );
      buffer.writeln(
        'Transport: ${DateHelpers.formatMoney(shift.transportExpense, currencyCode: _settings.currencyCode)}',
      );
      buffer.writeln(
        'Total: ${DateHelpers.formatMoney(shift.total, currencyCode: _settings.currencyCode)}',
      );
      buffer.writeln();
    }

    buffer.writeln(
      'Grand total: ${DateHelpers.formatMoney(_grandTotal, currencyCode: _settings.currencyCode)}',
    );

    await Share.share(
      buffer.toString(),
      subject: 'Payment summary',
    );

    await _setStatuses(PaymentStatus.sent);

    await AdService.instance.registerActionAndMaybeShow(
      onContinue: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
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
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        TopGlassButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment summary',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${widget.selectedDates.length} days',
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
                      padding: const EdgeInsets.all(20),
                      children: [
                        GlassCard(
                          child: Column(
                            children: [
                              _InfoRow(
                                label: 'Project',
                                value: _projectTitle(),
                              ),
                              _InfoRow(
                                label: 'Production',
                                value: _productionTitle(),
                              ),
                              _InfoRow(
                                label: 'Items',
                                value: '${_shifts.length}',
                                removeBottomPadding: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._shifts.map((shift) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: GlassCard(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          DateHelpers.formatShortDate(
                                            shift.date,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _statusTitle(
                                          shift.paymentStatus,
                                        ),
                                        style: TextStyle(
                                          color: _statusColor(
                                            shift.paymentStatus,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                    label: 'Hours',
                                    value:
                                    '${shift.startTime} - ${shift.endTime}',
                                  ),
                                  _InfoRow(
                                    label: 'Base',
                                    value: DateHelpers.formatMoney(
                                      shift.baseRate,
                                      currencyCode:
                                      _settings.currencyCode,
                                    ),
                                  ),
                                  _InfoRow(
                                    label: 'OT',
                                    value: DateHelpers.formatMoney(
                                      shift.overtimeTotal,
                                      currencyCode:
                                      _settings.currencyCode,
                                    ),
                                  ),
                                  _InfoRow(
                                    label: 'Transport',
                                    value: DateHelpers.formatMoney(
                                      shift.transportExpense,
                                      currencyCode:
                                      _settings.currencyCode,
                                    ),
                                  ),
                                  _InfoRow(
                                    label: 'Total',
                                    value: DateHelpers.formatMoney(
                                      shift.total,
                                      currencyCode:
                                      _settings.currencyCode,
                                    ),
                                    removeBottomPadding: true,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        GlassCard(
                          child: _MoneyLine(
                            label: 'Grand total',
                            value: DateHelpers.formatMoney(
                              _grandTotal,
                              currencyCode: _settings.currencyCode,
                            ),
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SoftGlassButton(
                                label: 'Share',
                                icon: Icons.share_rounded,
                                onTap: _shareSummary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SoftGlassButton(
                                label: 'Paid',
                                icon: Icons.check_circle_rounded,
                                onTap: () => _setStatuses(
                                  PaymentStatus.paid,
                                ),
                              ),
                            ),
                          ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.removeBottomPadding = false,
  });

  final String label;
  final String value;
  final bool removeBottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: removeBottomPadding ? 0 : 10),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(value),
        ],
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
      children: [
        Text(label),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 22 : 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}