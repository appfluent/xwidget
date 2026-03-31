import 'dart:typed_data';

import 'bundle_cache_stub.dart'
    if (dart.library.io) 'bundle_cache_io.dart'
    if (dart.library.js_interop) 'bundle_cache_web.dart';

abstract class BundleCache {
  factory BundleCache() => createBundleCache();

  Future<Uint8List?> loadBundle();
  Future<void> saveBundle(Uint8List bytes);
  Future<String?> loadETag();
  Future<void> saveETag(String eTag);
  Future<void> clear();
}
