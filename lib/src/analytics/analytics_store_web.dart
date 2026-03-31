import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'analytics_event.dart';
import 'analytics_store.dart';

AnalyticsStore createAnalyticsStore() => AnalyticsStoreWeb();

class AnalyticsStoreWeb implements AnalyticsStore {
  static const _dbName = 'xwidget_analytics';
  static const _storeName = 'events';
  static const _dbVersion = 1;

  String? _currentFileId;

  String _generateFileId() => DateTime.now().millisecondsSinceEpoch.toString();

  String _storeKey(EventType eventType, String fileId) {
    return '${eventType.storagePrefix}_$fileId';
  }

  Future<web.IDBDatabase> _openDb() async {
    final completer = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open(_dbName, _dbVersion);

    request.onupgradeneeded = (web.IDBVersionChangeEvent event) {
      final db = request.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    }.toJS;

    request.onsuccess = (web.Event event) {
      completer.complete(request.result as web.IDBDatabase);
    }.toJS;

    request.onerror = (web.Event event) {
      completer.completeError(Exception('Failed to open IndexedDB: ${request.error}'));
    }.toJS;

    return completer.future;
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

    // Write each type to its own IndexedDB entry
    for (final entry in byType.entries) {
      final key = _storeKey(entry.key, fileId);
      final newLines = StringBuffer();
      for (final event in entry.value) {
        newLines.writeln(jsonEncode(event.toJson()));
      }

      final db = await _openDb();
      final completer = Completer<void>();
      final transaction = db.transaction(_storeName.toJS, 'readwrite');
      final store = transaction.objectStore(_storeName);

      // Read existing content and append
      final getRequest = store.get(key.toJS);

      getRequest.onsuccess = (web.Event event) {
        var existing = '';
        final result = getRequest.result;
        if (result != null && !result.isUndefined) {
          existing = (result as JSString).toDart;
        }
        final updated = '$existing${newLines.toString()}';
        store.put(updated.toJS, key.toJS);
      }.toJS;

      transaction.oncomplete = (web.Event event) {
        completer.complete();
      }.toJS;

      transaction.onerror = (web.Event event) {
        completer.completeError(Exception('Failed to write analytics events to IndexedDB'));
      }.toJS;

      await completer.future;
    }
  }

  @override
  Future<void> rotateFiles() async {
    _currentFileId = null;
  }

  @override
  Future<Map<String, List<AnalyticsEvent>>> readUnsent(EventType eventType) async {
    final result = <String, List<AnalyticsEvent>>{};
    final prefix = '${eventType.storagePrefix}_';
    final currentKey = _currentFileId != null ? _storeKey(eventType, _currentFileId!) : null;

    final db = await _openDb();
    final completer = Completer<Map<String, List<AnalyticsEvent>>>();
    final transaction = db.transaction(_storeName.toJS, 'readonly');
    final store = transaction.objectStore(_storeName);
    final cursorRequest = store.openCursor();

    cursorRequest.onsuccess = (web.Event event) {
      final cursor = cursorRequest.result;
      if (cursor != null && !cursor.isUndefined) {
        final idbCursor = cursor as web.IDBCursorWithValue;
        final key = (idbCursor.key as JSString).toDart;

        // Only process entries matching this event type, skip active file
        if (key.startsWith(prefix) && key != currentKey) {
          final fileId = key.replaceFirst(prefix, '');
          try {
            final jsonlContent = (idbCursor.value as JSString).toDart;
            final events = <AnalyticsEvent>[];
            for (final line in jsonlContent.split('\n')) {
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
            // Corrupted entry, will be cleaned up on delete
          }
        }
        idbCursor.continue_();
      }
    }.toJS;

    transaction.oncomplete = (web.Event event) {
      completer.complete(result);
    }.toJS;

    transaction.onerror = (web.Event event) {
      completer.completeError(Exception('Failed to read analytics events from IndexedDB'));
    }.toJS;

    return completer.future;
  }

  @override
  Future<void> deleteFile(EventType eventType, String fileId) async {
    final key = _storeKey(eventType, fileId);
    final db = await _openDb();
    final completer = Completer<void>();
    final transaction = db.transaction(_storeName.toJS, 'readwrite');
    final store = transaction.objectStore(_storeName);
    store.delete(key.toJS);

    transaction.oncomplete = (web.Event event) {
      completer.complete();
    }.toJS;

    transaction.onerror = (web.Event event) {
      completer.completeError(Exception('Failed to delete analytics file from IndexedDB'));
    }.toJS;

    return completer.future;
  }

  @override
  @override
  Future<void> clear() async {
    try {
      final db = await _openDb();
      final completer = Completer<void>();
      final transaction = db.transaction(_storeName.toJS, 'readwrite');
      final store = transaction.objectStore(_storeName);
      store.clear();

      transaction.oncomplete = (web.Event event) {
        completer.complete();
      }.toJS;

      transaction.onerror = (web.Event event) {
        completer.completeError(Exception('Failed to clear analytics store'));
      }.toJS;

      await completer.future;
    } catch (_) {}
    _currentFileId = null;
  }
}
