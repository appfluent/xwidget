import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'fragment_bundle.dart';
import 'value_bundle.dart';

export 'cloud_resources.dart';
export 'local_resources.dart';
export 'fragment_bundle.dart';
export 'value_bundle.dart';

final _log = Logger('Resources');

/// Base class for resource loading configurations.
///
/// Subclass this to provide a custom resource loading strategy. The
/// built-in implementations are [LocalResources] (asset bundle) and
/// [CloudResources] (XWidget Cloud).
///
/// The active instance is set via [activate] (called by
/// [XWidget.initialize]) and accessed through [Resources.instance].
///
/// Subclasses implement [load] to populate [FragmentResourceBundle] and
/// [ValueResourceBundle] instances, then register them via
/// [replaceResourceBundles].
abstract class Resources with FragmentResourceMixin, ValueResourceMixin {
  static Resources? _active;

  static Resources get instance {
    final i = _active;
    if (i == null) {
      throw StateError('Resources not initialized. Call XWidget.initialize() first.');
    }
    return i;
  }

  // --- Registry ---

  final _bundlesByType = <Type, ResourceBundle>{};

  /// Returns the registered [ResourceBundle] of type [T].
  static T of<T extends ResourceBundle>() {
    final bundle = instance._bundlesByType[T];
    if (bundle != null) return bundle as T;
    throw Exception("Resource bundle of type '$T' not found");
  }

  /// Registers custom [ResourceBundle] instances.
  ///
  /// Throws if a bundle of the same type or path segment is already
  /// registered. Use [replaceResourceBundles] to overwrite.
  void addResourceBundles(List<ResourceBundle> bundles) {
    for (final bundle in bundles) {
      if (_bundlesByType.containsKey(bundle.runtimeType)) {
        throw Exception(
          "Resource bundle of type '${bundle.runtimeType}' "
          "handling path segment '${bundle.pathSegment}' conflicts with an "
          "existing bundle of the same type. Use "
          "'replaceResourceBundles(List<ResourceBundle>)' to replace "
          "existing bundles.",
        );
      }
      _bundlesByType[bundle.runtimeType] = bundle;
    }
  }

  /// Registers [ResourceBundle] instances, replacing any existing
  /// bundles that conflict by type.
  void replaceResourceBundles(List<ResourceBundle> bundles) {
    for (final bundle in bundles) {
      _bundlesByType[bundle.runtimeType] = bundle;
    }
  }

  // --- Lifecycle ---

  /// Sets this instance as the active singleton and calls [load].
  ///
  /// Called by [XWidget.initialize]. Disposes any previously active
  /// instance before activating this one.
  Future<void> activate() async {
    await _active?.dispose();
    _active = this;
    await load();
    _log.info('Resources loaded.');
  }

  /// Subclasses implement this to populate resource bundles.
  ///
  /// Create [FragmentResourceBundle] and [ValueResourceBundle]
  /// instances, load content into them, and register them via
  /// [replaceResourceBundles].
  Future<void> load();

  /// Releases resources held by this instance. Called automatically
  /// when a new instance is [activate]d. Override to clean up
  /// subclass-specific resources (watchers, connections, etc.).
  Future<void> dispose() async {}
}

abstract class ResourceBundle {
  final String pathSegment;

  ResourceBundle(this.pathSegment);

  Future<void> loadFromAssetBundle(
    String fileName,
    String resPath,
    String resName,
    String resExt,
    AssetBundle assetBundle,
  );

  void loadFromString(String resPath, String resName, String resExt, String content);
}
