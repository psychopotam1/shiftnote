import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  static const String _fileName = 'shiftnote_backup.json';
  static const String _androidFolderName = 'ShiftNote';

  Future<Directory> _getBackupDirectory() async {
    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }

    if (Platform.isAndroid) {
      final Directory? baseDir = await getExternalStorageDirectory();

      if (baseDir == null) {
        return getApplicationDocumentsDirectory();
      }

      final String rootPath = baseDir.path.split('/Android/').first;
      final Directory documentsDir =
      Directory('$rootPath/Documents/$_androidFolderName');

      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      return documentsDir;
    }

    return getApplicationDocumentsDirectory();
  }

  Future<File> _getBackupFile() async {
    final directory = await _getBackupDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<String> getBackupPath() async {
    final file = await _getBackupFile();
    return file.path;
  }

  Future<void> backupNow(Map<String, dynamic> data) async {
    final file = await _getBackupFile();

    final payload = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
      'data': data,
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
  }

  Future<Map<String, dynamic>?> restoreBackup() async {
    final file = await _getBackupFile();

    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      return decoded;
    }

    return null;
  }

  Future<Map<String, dynamic>?> importBackupFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final pickedFile = result.files.single;

    String? content;

    if (pickedFile.bytes != null) {
      content = utf8.decode(pickedFile.bytes!);
    } else if (pickedFile.path != null) {
      content = await File(pickedFile.path!).readAsString();
    }

    if (content == null || content.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(content);

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      return decoded;
    }

    return null;
  }

  Future<bool> backupExists() async {
    final file = await _getBackupFile();
    return file.exists();
  }

  Future<void> deleteBackup() async {
    final file = await _getBackupFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}