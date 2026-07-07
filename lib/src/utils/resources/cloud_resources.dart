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
import '../path.dart';
import 'resources.dart';

final _log = Logger('CloudResources');

/// Loads resources from XWidget Cloud's content server.
///
/// Reads the channel's pointer record for the given [channel] and
/// [version] (a small JSON file, cached with ETag-based conditional
/// GETs), then downloads the immutable bundle tarball it references.
/// Downloads are verified against the pointer's sha256.
///
/// Path parameters ([fragmentsPath], [valuesPath]) default to values
/// from [XWidget.config] when not provided explicitly. Constructor
/// arguments override config values when passed.
///
/// If the pointer or bundle download fails, falls back to the cached
/// bundle — but only when the cache matches this [channel] and
/// [version]. If the cache is missing or mismatched, falls back to
/// loading from the asset bundle at the same paths.
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

    final hashedKey = hashKey(storageKey);
    final pointerUrl = '$_contentBaseUrl/$hashedKey/$channel/$version.json';
    final cache = BundleCache();

    // The cached bundle is only usable when it belongs to this channel and
    // version. A mismatched cache (channel switch, app upgrade) is treated
    // as no cache at all.
    final cached = await cache.loadMetadata();
    final cacheMatches = cached != null && cached.channel == channel && cached.version == version;

    // Seed analytics with the revision the client currently holds. Events
    // fired before this (early errors) carry a null revision — bundle state
    // unknown. Updated again below if the pointer resolves a newer revision.
    if (cacheMatches) {
      Analytics.setRevision(cached.revision);
    }

    Uint8List? bundleBytes;
    int? revision;

    try {
      final headers = <String, String>{};
      if (cacheMatches && cached.etag != null) {
        headers['If-None-Match'] = cached.etag!;
        _log.fine('Requesting pointer with cached ETag');
      } else {
        _log.fine('Requesting pointer (no usable cached ETag)');
      }

      final response = await http
          .get(Uri.parse(pointerUrl), headers: headers)
          .timeout(downloadTimeout);

      _log.fine('Pointer response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final pointer = json.decode(response.body) as Map<String, dynamic>;
        final pointerRevision = (pointer['revision'] as num).toInt();
        final pointerSha256 = pointer['sha256'] as String;
        final pointerPath = pointer['url'] as String; // relative to the storage key hash
        final pointerETag = response.headers['etag'];

        if (cacheMatches && cached.revision == pointerRevision && cached.sha256 == pointerSha256) {
          // pointer was rewritten but references the bytes we already have
          _log.info('Pointer matches cached bundle, loading from cache');
          bundleBytes = await cache.loadBundle();
          revision = cached.revision;
          if (bundleBytes != null) {
            Analytics.trackDownload(isCacheHit: true, revision: revision);
          }
        }

        if (bundleBytes == null) {
          bundleBytes = await _downloadBundle(
            '$_contentBaseUrl/$hashedKey/$pointerPath',
            pointerSha256,
            pointerRevision,
          );
          revision = pointerRevision;
          await cache.saveBundle(bundleBytes);
          await cache.saveMetadata(
            BundleMetadata(
              channel: channel,
              version: version,
              revision: pointerRevision,
              sha256: pointerSha256,
              etag: pointerETag,
            ),
          );
          _log.fine('Bundle cached');
          Analytics.trackDownload(revision: revision);
        }
      } else if (response.statusCode == 304) {
        _log.info('Pointer not modified, loading from cache');
        bundleBytes = await cache.loadBundle();
        revision = cached!.revision; // 304 implies a cached ETag, which implies metadata
        Analytics.trackDownload(isCacheHit: true, revision: revision);
      } else {
        // includes 404 (nothing published) — treated as an error; the client
        // keeps serving its cache. Taking content down is done by publishing
        // a different deployment, not by unpublish alone.
        throw Exception(
          'Deployment lookup returned ${response.statusCode} for channel '
          '$channel, version $version',
        );
      }
    } catch (e) {
      // Pointer fetch failed. The event carries the revision the client
      // currently holds (seeded from the cache above, or null on a fresh
      // install) — it identifies the cohort that failed to check for
      // updates, not the revision that failed.
      _log.warning('Pointer request failed: $e');
      Analytics.trackError(error: e);

      if (cacheMatches) {
        _log.info('Falling back to cached bundle');
        bundleBytes = await cache.loadBundle();
        revision = cached.revision;
      } else {
        _log.info('No matching cached bundle for channel=$channel, version=$version');
      }
    }

    if (bundleBytes != null && revision != null) {
      Analytics.setRevision(revision);
      _loadFromArchive(bundleBytes);
    } else {
      _log.info('No usable bundle, falling back to local assets');
      await _fallbackToLocal();
    }
  }

  /// Downloads the bundle tarball and verifies it against the pointer's
  /// sha256. Throws on failure; the caller's fallback ladder handles it.
  Future<Uint8List> _downloadBundle(String url, String expectedSha256, int revision) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(downloadTimeout);
      if (response.statusCode != 200) {
        throw Exception(
          'Deployment download returned ${response.statusCode} for channel '
          '$channel, version $version, rev $revision',
        );
      }

      final bytes = response.bodyBytes;
      final bodySha256 = sha256.convert(bytes).toString();
      if (bodySha256 != expectedSha256) {
        throw Exception(
          'Deployment verification failed for channel $channel, version '
          '$version, rev $revision: sha256 mismatch. '
          'Expected: $expectedSha256, Got: $bodySha256',
        );
      }
      _log.fine('Downloaded bundle: ${bytes.length} bytes, sha256 verified');
      return bytes;
    } catch (e) {
      // Bundle failures report the target revision — the pointer already
      // resolved, and the target identifies the tarball that failed.
      Analytics.trackError(error: e, isDownload: true, revision: revision);
      rethrow;
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
          final parts = splitPath(relativePath);
          if (parts != null) {
            final content = utf8.decode(file.content as List<int>);
            fragments.loadFromString(parts.path, parts.name, parts.ext, content);
            fragmentCount++;
          }
        } else if (name.startsWith(valPrefix)) {
          final relativePath = name.substring(valPrefix.length);
          final parts = splitPath(relativePath);
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
    final result = await loadAssetResourcesFromManifest(
      manifestMap: manifestMap,
      assetBundle: rootBundle,
      fragmentsPath: fragmentsPath,
      valuesPath: valuesPath,
    );

    _log.info(
      'Fallback local resources loaded: ${result.fragmentCount} fragments, '
      '${result.valueFileCount} value files',
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
