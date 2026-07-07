import 'dart:typed_data';

import 'bundle_cache_stub.dart'
    if (dart.library.io) 'bundle_cache_io.dart'
    if (dart.library.js_interop) 'bundle_cache_web.dart';

/// Metadata for the cached bundle. Persisted alongside the bundle bytes so
/// the cache can be validated against the requesting context (channel +
/// version) and so the client knows its revision without a fresh pointer
/// read (304 and offline paths).
class BundleMetadata {
  final String channel;
  final String version;
  final int revision;
  final String sha256;
  final String? etag; // pointer json ETag, used for If-None-Match

  BundleMetadata({
    required this.channel,
    required this.version,
    required this.revision,
    required this.sha256,
    this.etag,
  });

  Map<String, dynamic> toJson() => {
    'channel': channel,
    'version': version,
    'revision': revision,
    'sha256': sha256,
    'etag': etag,
  };

  /// Returns null when the record is malformed — callers treat that
  /// as no cache.
  static BundleMetadata? fromJson(Map<String, dynamic> json) {
    final channel = json['channel'];
    final version = json['version'];
    final revision = json['revision'];
    final sha256 = json['sha256'];
    if (channel is! String || version is! String || revision is! int || sha256 is! String) {
      return null;
    }
    return BundleMetadata(
      channel: channel,
      version: version,
      revision: revision,
      sha256: sha256,
      etag: json['etag'] as String?,
    );
  }
}

abstract class BundleCache {
  factory BundleCache() => createBundleCache();

  Future<Uint8List?> loadBundle();
  Future<void> saveBundle(Uint8List bytes);
  Future<BundleMetadata?> loadMetadata();
  Future<void> saveMetadata(BundleMetadata metadata);
  Future<void> clear();
}
