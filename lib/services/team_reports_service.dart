import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/member_report.dart';
import '../models/shift_entry.dart';

class TeamReportsService {
  static const String _storageKey = 'imported_member_reports';
  static const String _folderName = 'ShiftNote/reports';

  Future<List<MemberReport>> getImportedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <MemberReport>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <MemberReport>[];
    return decoded
        .whereType<Map>()
        .map((item) => MemberReport.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<MemberReport>> getReportsByProject(String projectName) async {
    final normalized = projectName.trim().toLowerCase();
    if (normalized.isEmpty || normalized == '—') return <MemberReport>[];
    final all = await getImportedReports();
    return all.where((report) => report.projectName.trim().toLowerCase() == normalized).toList()
      ..sort((a, b) => a.participantName.compareTo(b.participantName));
  }

  Future<void> saveImportedReport(MemberReport incoming) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = await getImportedReports();
    reports.removeWhere((report) => report.matchKey == incoming.matchKey);
    reports.add(incoming);
    await prefs.setString(
      _storageKey,
      jsonEncode(reports.map((report) => report.toMap()).toList()),
    );
  }

  Future<MemberReport?> pickReportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json', 'shiftnote'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    String? contents;
    if (picked.bytes != null) {
      contents = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      contents = await File(picked.path!).readAsString();
    }
    if (contents == null || contents.trim().isEmpty) return null;
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid report file');
    }
    return MemberReport.fromMap(decoded);
  }

  Future<File> exportMyReport({
    required String participantName,
    required List<ShiftEntry> shifts,
  }) async {
    if (shifts.isEmpty) {
      throw ArgumentError('Cannot export an empty report');
    }
    final sorted = List<ShiftEntry>.from(shifts)..sort((a, b) => a.date.compareTo(b.date));
    final project = _singleText(sorted.map((shift) => shift.projectName), fallback: 'Mixed projects');
    final production = _singleText(sorted.map((shift) => shift.productionName), fallback: 'Mixed productions');
    final first = sorted.first.date;
    final last = sorted.last.date;
    final key = '${_safeFile(participantName)}_${_safeFile(project)}_${_date(first)}_${_date(last)}';
    final report = MemberReport(
      reportId: key,
      participantName: participantName.trim(),
      projectName: project,
      productionName: production,
      periodStart: DateTime(first.year, first.month, first.day),
      periodEnd: DateTime(last.year, last.month, last.day),
      exportedAt: DateTime.now(),
      revision: 1,
      shifts: sorted,
    );
    final directory = await _reportsDirectory();
    final file = File('${directory.path}/$key.shiftnote');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(report.toMap()), flush: true);
    return file;
  }

  Future<Directory> _reportsDirectory() async {
    Directory base;
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        final rootPath = external.path.split('/Android/').first;
        base = Directory('$rootPath/Documents/$_folderName');
      } else {
        base = Directory('${(await getApplicationDocumentsDirectory()).path}/reports');
      }
    } else {
      base = Directory('${(await getApplicationDocumentsDirectory()).path}/reports');
    }
    if (!await base.exists()) await base.create(recursive: true);
    return base;
  }

  String _date(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _safeFile(String value) => value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9а-яА-ЯіїєІЇЄ_-]+'), '_');
  String _singleText(Iterable<String> values, {required String fallback}) {
    final cleaned = values.map((v) => v.trim()).where((v) => v.isNotEmpty).toSet();
    return cleaned.length == 1 ? cleaned.first : fallback;
  }
}
