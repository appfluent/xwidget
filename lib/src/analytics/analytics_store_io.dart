import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'analytics_event.dart';
import 'analytics_store.dart';

AnalyticsStore createAnalyticsStore() => AnalyticsStoreIo();

class AnalyticsStoreIo implements AnalyticsStore {
  static const _dirName = 'xwidget_cloud/analytics';
  static const _fileExt = '.jsonl';

  String? _currentFileId;

  Future<Directory> _getStoreDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final storeDir = Directory('${appDir.path}/$_dirName');
    if (!await storeDir.exists()) {
      await storeDir.create(recursive: true);
    }
    return storeDir;
  }

  String _generateFileId() => DateTime.now().millisecondsSinceEpoch.toString();

  String _fileName(EventType eventType, String fileId) =>
      '${eventType.storagePrefix}_$fileId$_fileExt';

  Future<File> _getFile(EventType eventType, String fileId) async {
    final dir = await _getStoreDir();
    return File('${dir.path}/${_fileName(eventType, fileId)}');
  }

  @override
  @override
  Future<void> writeEvents(List<AnalyticsEvent> events) async {
    if (events.isEmpty) return;
    _currentFileId ??= _generateFileId();
    final fileId = _currentFileId!;

    // Split events by type
    final byType = <EventType, List<AnalyticsEvent>>{};
    for (final event in events) {
      final eventType = EventType.eventTypeFor(event);
      (byType[eventType] ??= []).add(event);
    }

    // Write each type to its own file
    for (final entry in byType.entries) {
      final file = await _getFile(entry.key, fileId);
      final sink = file.openWrite(mode: FileMode.append);
      for (final event in entry.value) {
        sink.writeln(jsonEncode(event.toJson()));
      }
      await sink.flush();
      await sink.close();
    }
  }

  @override
  @override
  Future<void> rotateFiles() async {
    final fileId = _currentFileId;
    if (fileId != null) {
      // Verify at least one file exists with content
      final dir = await _getStoreDir();
      var hasContent = false;
      for (final eventType in EventType.values) {
        final file = File('${dir.path}/${_fileName(eventType, fileId)}');
        if (await file.exists() && await file.length() > 0) {
          hasContent = true;
          break;
        }
      }
      if (!hasContent) {
        _currentFileId = null;
        return;
      }
    }
    _currentFileId = null;
  }

  @override
  Future<Map<String, List<AnalyticsEvent>>> readUnsent(EventType eventType) async {
    final result = <String, List<AnalyticsEvent>>{};
    final dir = await _getStoreDir();

    if (!await dir.exists()) return result;

    final prefix = '${eventType.storagePrefix}_';

    await for (final entity in dir.list()) {
      if (entity is File &&
          entity.path.endsWith(_fileExt) &&
          entity.uri.pathSegments.last.startsWith(prefix)) {
        final fileName = entity.uri.pathSegments.last;
        final fileId = fileName.replaceFirst(prefix, '').replaceFirst(_fileExt, '');

        // Skip the current active file
        if (fileId == _currentFileId) continue;

        try {
          final lines = await entity.readAsLines();
          final events = <AnalyticsEvent>[];
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;
            try {
              final json = jsonDecode(trimmed) as Map<String, dynamic>;
              events.add(AnalyticsEvent.fromJson(eventType, json));
            } catch (_) {
              // Skip corrupted lines
            }
          }
          if (events.isNotEmpty) {
            result[fileId] = events;
          }
        } catch (_) {
          // Corrupted file, delete it
          await entity.delete();
        }
      }
    }
    return result;
  }

  @override
  Future<void> deleteFile(EventType eventType, String fileId) async {
    final file = await _getFile(eventType, fileId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _getStoreDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
    _currentFileId = null;
  }
}
