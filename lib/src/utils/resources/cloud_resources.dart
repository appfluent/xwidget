import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../../analytics/analytics.dart';
import '../../xwidget.dart';
import '../bundle/bundle_cache.dart';
import '../hash.dart';
import 'resources.dart';
import '../version.dart';

final _log = Logger('CloudResources');

/// Loads resources from XWidget Cloud's content server.
///
/// Downloads a compressed tarball for the given [channel] and
/// [version], caches it locally with ETag-based conditional GETs,
/// and verifies the download's MD5 against the response ETag.
///
/// Path parameters ([fragmentsPath], [valuesPath]) default to values
/// from [XWidget.config] when not provided explicitly. Constructor
/// arguments override config values when passed.
///
/// If both the download and local cache fail, falls back to loading
/// from the asset bundle at the same paths.
class CloudResources extends Resources {
  static const _contentBaseUrl = String.fromEnvironment(
    'XWIDGET_CONTENT_URL',
    defaultValue: 'https://content.xwidget.dev',
  );

  final String projectKey;
  final String storageKey;
  final String channel;
  final String version;
  final String? _fragmentsPath;
  final String? _valuesPath;
  final Duration downloadTimeout;

  String get fragmentsPath => _fragmentsPath ?? XWidget.config.fragmentsPath;
  String get valuesPath => _valuesPath ?? XWidget.config.valuesPath;

  CloudResources({
    required this.projectKey,
    required this.storageKey,
    required this.channel,
    required this.version,
    String? fragmentsPath,
    String? valuesPath,
    this.downloadTimeout = const Duration(seconds: 15),
  }) : _fragmentsPath = fragmentsPath,
       _valuesPath = valuesPath;

  @override
  Future<void> load() async {
    await Analytics.initialize(projectKey: projectKey, channel: channel, version: version);

    _log.info('Loading cloud resources for channel=$channel, version=$version');

    final hashedKey = hashStorageKey(storageKey);
    final ver = Version.parse(version);
    final url = '$_contentBaseUrl/$hashedKey/$channel/${ver.number}.tar.gz';
    final cache = BundleCache();
    Uint8List? bundleBytes;

    try {
      final eTag = await cache.loadETag();
      final headers = <String, String>{};
      if (eTag != null) {
        headers['If-None-Match'] = eTag;
        _log.fine('Requesting bundle with cached ETag');
      } else {
        _log.fine('Requesting bundle (no cached ETag)');
      }

      final response = await http.get(Uri.parse(url), headers: headers).timeout(downloadTimeout);

      _log.fine('Content server response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseETag = response.headers['etag'];

        // Verify MD5 against ETag
        if (responseETag != null) {
          final bodyMd5 = md5.convert(response.bodyBytes).toString();
          final cleanETag = responseETag.replaceAll('"', '');
          if (bodyMd5 != cleanETag) {
            throw Exception(
              'Bundle MD5 verification failed. '
              'Expected: $cleanETag, Got: $bodyMd5',
            );
          }
          _log.fine('Bundle MD5 verified');
        }

        bundleBytes = response.bodyBytes;
        _log.fine('Downloaded bundle: ${bundleBytes.length} bytes');
        await cache.saveBundle(bundleBytes);
        if (responseETag != null) {
          await cache.saveETag(responseETag);
        }
        _log.fine('Bundle cached');
        Analytics.trackDownload();
      } else if (response.statusCode == 304) {
        _log.info('Bundle not modified, loading from cache');
        bundleBytes = await cache.loadBundle();
        Analytics.trackDownload(isCacheHit: true);
      } else {
        throw Exception('Content server returned ${response.statusCode}');
      }
    } catch (e) {
      // Network failure or unexpected error — try cached bundle
      _log.warning('Content download request failed: $e');
      _log.info('Falling back to previously cached bundle, if available');
      bundleBytes = await cache.loadBundle();
      Analytics.trackError(error: e, isDownload: true);
    }

    if (bundleBytes != null) {
      _loadFromArchive(bundleBytes);
    } else {
      _log.info('No cached bundle available, falling back to local assets');
      await _fallbackToLocal();
    }
  }

  void _loadFromArchive(Uint8List bytes) {
    final gzBytes = GZipDecoder().decodeBytes(bytes);
    final archive = TarDecoder().decodeBytes(gzBytes);

    final fragments = FragmentResourceBundle(fragmentsPath);
    final values = ValueResourceBundle(valuesPath);

    // Normalize paths — ensure they end with '/' for prefix matching
    final fragPrefix = fragmentsPath.endsWith('/') ? fragmentsPath : '$fragmentsPath/';
    final valPrefix = valuesPath.endsWith('/') ? valuesPath : '$valuesPath/';

    var fragmentCount = 0;
    var valueFileCount = 0;

    for (final file in archive.files) {
      if (file.isFile) {
        final name = file.name;
        if (name.startsWith(fragPrefix)) {
          final relativePath = name.substring(fragPrefix.length);
          final parts = splitFileName(relativePath);
          if (parts != null) {
            final content = utf8.decode(file.content as List<int>);
            fragments.loadFromString(parts.path, parts.name, parts.ext, content);
            fragmentCount++;
          }
        } else if (name.startsWith(valPrefix)) {
          final relativePath = name.substring(valPrefix.length);
          final parts = splitFileName(relativePath);
          if (parts != null) {
            final content = utf8.decode(file.content as List<int>);
            values.loadFromString(parts.path, parts.name, parts.ext, content);
            valueFileCount++;
          }
        }
      }
    }

    replaceResourceBundles([fragments, values]);
    _log.info(
      'Archive resources loaded: $fragmentCount fragments, '
      '$valueFileCount value files',
    );
  }

  /// Fallback: loads from asset bundle when cloud and cache both fail.
  Future<void> _fallbackToLocal() async {
    _log.info(
      'Loading local resources from fragmentsPath=$fragmentsPath, '
      'valuesPath=$valuesPath',
    );

    final manifestMap = await _loadFallbackManifest();

    final fragments = FragmentResourceBundle(fragmentsPath);
    final values = ValueResourceBundle(valuesPath);

    var fragmentCount = 0;
    var valueFileCount = 0;

    for (final fileName in manifestMap.keys) {
      if (fileName.startsWith('$fragmentsPath/')) {
        final relativePath = fileName.substring(fragmentsPath.length + 1);
        final parts = splitFileName(relativePath);
        if (parts != null) {
          await fragments.loadFromAssetBundle(
            fileName,
            parts.path,
            parts.name,
            parts.ext,
            rootBundle,
          );
          fragmentCount++;
        }
      } else if (fileName.startsWith('$valuesPath/')) {
        final relativePath = fileName.substring(valuesPath.length + 1);
        final parts = splitFileName(relativePath);
        if (parts != null) {
          await values.loadFromAssetBundle(fileName, parts.path, parts.name, parts.ext, rootBundle);
          valueFileCount++;
        }
      }
    }

    replaceResourceBundles([fragments, values]);
    _log.info(
      'Fallback local resources loaded: $fragmentCount fragments, '
      '$valueFileCount value files',
    );
  }

  Future<dynamic> _loadFallbackManifest() async {
    try {
      final data = await rootBundle.load('AssetManifest.bin');
      return const StandardMessageCodec().decodeMessage(data);
    } catch (_) {
      final jsonStr = await rootBundle.loadString('AssetManifest.json');
      return json.decode(jsonStr);
    }
  }
}
