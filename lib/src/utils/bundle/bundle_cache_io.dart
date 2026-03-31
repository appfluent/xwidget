import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'bundle_cache.dart';

/// Creates the platform-specific [BundleCache] implementation for
/// native (iOS/Android/desktop) targets.
BundleCache createBundleCache() => BundleCacheIo();

/// Native file system implementation of [BundleCache].
///
/// Persists downloaded XWidget Cloud resource bundles and their
/// associated ETags to the application documents directory under
/// an `xwidget_cloud` subdirectory. This enables offline access to
/// the most recently downloaded bundle and conditional downloads
/// via ETag-based cache validation against the content server.
///
/// File layout:
///
///     <app_documents>/xwidget_cloud/
///       bundle.tar.gz   — the compressed resource bundle
///       etag            — the ETag string from the last download
///
/// All read operations silently return `null` on failure (missing
/// files, permission errors, corrupt data) to allow graceful
/// fallback to a fresh download.
class BundleCacheIo implements BundleCache {
  static const _dirName = 'xwidget_cloud';
  static const _bundleFileName = 'bundle.tar.gz';
  static const _etagFileName = 'etag';

  /// Loads the cached resource bundle from disk.
  ///
  /// Returns the raw bytes of the compressed bundle, or `null` if
  /// no cached bundle exists or an error occurs during reading.
  @override
  Future<Uint8List?> loadBundle() async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/$_bundleFileName');
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (_) {}
    return null;
  }

  /// Saves a resource bundle to disk.
  ///
  /// Writes [bytes] to the cache directory with `flush: true` to
  /// ensure durability before returning.
  @override
  Future<void> saveBundle(Uint8List bytes) async {
    final dir = await _getCacheDir();
    final file = File('${dir.path}/$_bundleFileName');
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Loads the cached ETag from disk.
  ///
  /// The ETag is used for conditional requests against the content server to
  /// avoid re-downloading an unchanged bundle. Returns `null` if
  /// no ETag has been cached or an error occurs during reading.
  @override
  Future<String?> loadETag() async {
    try {
      final dir = await _getCacheDir();
      final file = File('${dir.path}/$_etagFileName');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (_) {}
    return null;
  }

  /// Saves an ETag string to disk.
  ///
  /// Persists the [eTag] returned from the content server so subsequent
  /// downloads can use conditional requests. Written with
  /// `flush: true` to ensure durability.
  @override
  Future<void> saveETag(String eTag) async {
    final dir = await _getCacheDir();
    final file = File('${dir.path}/$_etagFileName');
    await file.writeAsString(eTag, flush: true);
  }

  /// Deletes the entire cache directory and its contents.
  ///
  /// Silently succeeds if the directory does not exist or if an
  /// error occurs during deletion.
  @override
  Future<void> clear() async {
    try {
      final dir = await _getCacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_dirName');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }
}
