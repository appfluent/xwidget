import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'bundle_cache.dart';

BundleCache createBundleCache() => BundleCacheWeb();

class BundleCacheWeb implements BundleCache {
  static const _dbName = 'xwidget_cloud';
  static const _storeName = 'cache';
  static const _bundleKey = 'bundle';
  static const _eTagKey = 'etag';
  static const _dbVersion = 1;

  @override
  Future<Uint8List?> loadBundle() async {
    return _get<Uint8List>(_bundleKey);
  }

  @override
  Future<void> saveBundle(Uint8List bytes) async {
    await _put(_bundleKey, bytes.buffer.toJS);
  }

  @override
  Future<String?> loadETag() async {
    return _get<String>(_eTagKey);
  }

  @override
  Future<void> saveETag(String eTag) async {
    await _put(_eTagKey, eTag.toJS);
  }

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
        completer.completeError(Exception('Failed to clear IndexedDB store'));
      }.toJS;

      return completer.future;
    } catch (_) {}
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

  Future<T?> _get<T>(String key) async {
    try {
      final db = await _openDb();
      final completer = Completer<T?>();
      final transaction = db.transaction(_storeName.toJS, 'readonly');
      final store = transaction.objectStore(_storeName);
      final request = store.get(key.toJS);

      request.onsuccess = (web.Event event) {
        final result = request.result;
        if (result == null || result.isUndefined) {
          completer.complete(null);
        } else if (T == Uint8List) {
          // Result is an ArrayBuffer, convert to Uint8List
          final arrayBuffer = result as JSArrayBuffer;
          completer.complete(arrayBuffer.toDart.asUint8List() as T);
        } else if (T == String) {
          completer.complete((result as JSString).toDart as T);
        } else {
          completer.complete(null);
        }
      }.toJS;

      request.onerror = (web.Event event) {
        completer.complete(null);
      }.toJS;

      return completer.future;
    } catch (_) {
      return null;
    }
  }

  Future<void> _put(String key, JSAny value) async {
    final db = await _openDb();
    final completer = Completer<void>();
    final transaction = db.transaction(_storeName.toJS, 'readwrite');
    final store = transaction.objectStore(_storeName);
    store.put(value, key.toJS);

    transaction.oncomplete = (web.Event event) {
      completer.complete();
    }.toJS;

    transaction.onerror = (web.Event event) {
      completer.completeError(Exception('Failed to write to IndexedDB'));
    }.toJS;

    return completer.future;
  }
}
