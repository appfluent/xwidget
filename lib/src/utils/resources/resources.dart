import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';
import 'package:xwidget_el/xwidget_el.dart';

import '../extensions.dart';
import '../path.dart';
import '../xml.dart';

export 'local_resources.dart';
export 'cloud_resources.dart';

final _log = Logger('Resources');

// =============================================================================
// Resources (abstract base)
// =============================================================================

/// Base class for resource loading configurations.
///
/// Subclass this to provide a custom resource loading strategy. The
/// built-in implementations are [LocalResources] (asset bundle) and
/// [CloudResources] (XWidget Cloud).
///
/// The active instance is set via [activate] (called by
/// [XWidget.initialize]) and accessed through [Resources.instance].
///
/// The parsed-XML cache and all accessors live here. Subclasses
/// implement [load] to populate [FragmentResourceBundle] and
/// [ValueResourceBundle] instances, then register them via
/// [replaceResourceBundles].
abstract class Resources {
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
  final _bundlesByPath = <String, ResourceBundle>{};

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
      if (_bundlesByPath.containsKey(bundle.pathSegment)) {
        throw Exception(
          "Resource bundle of type '${bundle.runtimeType}' "
          "handling path segment '${bundle.pathSegment}' conflicts with "
          "an existing bundle handling the same path. Use "
          "'replaceResourceBundles(List<ResourceBundle>)' to replace "
          "existing bundles.",
        );
      }

      _bundlesByType[bundle.runtimeType] = bundle;
      _bundlesByPath[bundle.pathSegment] = bundle;
    }
  }

  /// Registers [ResourceBundle] instances, replacing any existing
  /// bundles that conflict by type or path segment.
  void replaceResourceBundles(List<ResourceBundle> bundles) {
    for (final bundle in bundles) {
      final removedByType = _bundlesByType.remove(bundle.runtimeType);
      if (removedByType != null) {
        _bundlesByPath.remove(removedByType.pathSegment);
      }

      final removedByPath = _bundlesByPath.remove(bundle.pathSegment);
      if (removedByPath != null) {
        _bundlesByType.remove(removedByPath.runtimeType);
      }

      _bundlesByType[bundle.runtimeType] = bundle;
      _bundlesByPath[bundle.pathSegment] = bundle;
    }
  }

  // --- Parsed XML cache ---

  /// Parsed XML document cache. `null` means caching is disabled.
  final Map<String, XmlDocument>? _xmlCache;

  Resources({bool cacheParsedXml = true})
    : _xmlCache = cacheParsedXml ? <String, XmlDocument>{} : null;

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

  // --- Fragment accessors ---

  /// Returns the parsed [XmlDocument] for the given fully-qualified
  /// fragment name. Uses the internal cache when enabled.
  XmlDocument getFragment(String fqn) {
    final cached = _xmlCache?[fqn];
    if (cached != null) return cached;

    final bundle = _bundlesByType[FragmentResourceBundle];
    if (bundle == null) {
      throw Exception('FragmentResourceBundle not loaded');
    }
    final xmlString = (bundle as FragmentResourceBundle).getFragmentRaw(fqn);
    final doc = XmlParser.parse(SourceCode(xmlString, filePath: fqn, withPosition: true));
    _xmlCache?[fqn] = doc;
    return doc;
  }

  /// Clears the parsed XML cache. Safe to call when caching is
  /// disabled.
  void clearXmlCache() {
    _xmlCache?.clear();
  }

  /// Resolves a fragment name to its fully-qualified path.
  String getFragmentFqn(String name, [String? relativeTo]) {
    final bundle = _bundlesByType[FragmentResourceBundle];
    if (bundle == null) {
      throw Exception('FragmentResourceBundle not loaded');
    }
    return (bundle as FragmentResourceBundle).getFragmentFqn(name, relativeTo);
  }

  // --- Value accessors ---

  ValueResourceBundle get _values {
    final bundle = _bundlesByType[ValueResourceBundle];
    if (bundle == null) {
      throw Exception('ValueResourceBundle not loaded');
    }
    return bundle as ValueResourceBundle;
  }

  String getString(String name) => _values.getString(name);
  bool getBool(String name) => _values.getBool(name);
  int getInt(String name) => _values.getInt(name);
  double getDouble(String name) => _values.getDouble(name);
  Color getColor(String name) => _values.getColor(name);
  String getColorString(String name) => _values.getColorString(name);
}

// =============================================================================
// Utilities
// =============================================================================

/// Splits a relative file path into its directory path, file name, and
/// extension components.
///
/// For example, `subdir/my_file.xml` returns
/// `(path: "subdir/", name: "my_file", ext: "xml")`.
FileNameParts? splitFileName(String relativePath) {
  final lastSlash = relativePath.lastIndexOf('/');
  final lastDot = relativePath.lastIndexOf('.');

  if (lastDot < 0) return null; // no extension

  final path = lastSlash >= 0 ? relativePath.substring(0, lastSlash + 1) : '';
  final name = relativePath.substring(lastSlash + 1, lastDot);
  final ext = relativePath.substring(lastDot + 1);

  if (name.isEmpty || ext.isEmpty) return null;

  return FileNameParts(path: path, name: name, ext: ext);
}

class FileNameParts {
  final String path;
  final String name;
  final String ext;

  FileNameParts({required this.path, required this.name, required this.ext});
}

// =============================================================================
// ResourceBundle
// =============================================================================

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

// =============================================================================
// ValueResourceBundle
// =============================================================================

class ValueResourceBundle extends ResourceBundle {
  final _strings = <String, String>{};
  final _bools = <String, bool>{};
  final _ints = <String, int>{};
  final _doubles = <String, double>{};
  final _colors = <String, Color>{};

  ValueResourceBundle(super.pathSegment);

  @override
  Future<void> loadFromAssetBundle(
    String fileName,
    String resPath,
    String resName,
    String resExt,
    AssetBundle assetBundle,
  ) async {
    if (resExt == "xml") {
      final xml = await assetBundle.loadString(fileName);
      _parseValuesXml(xml);
    }
  }

  @override
  void loadFromString(String resPath, String resName, String resExt, String content) {
    if (resExt == "xml") {
      _parseValuesXml(content);
    }
  }

  void _parseValuesXml(String xml) {
    final document = XmlDocument.parse(xml);
    final root = document.getElement("resources");
    if (root != null) {
      for (final element in root.childElements) {
        final resourceType = element.name.qualified;
        final resourceName = element.getAttribute("name");
        final resourceValue = element.innerText.trim();
        if (resourceName != null && resourceValue.isNotEmpty) {
          switch (resourceType) {
            case "string":
              _strings[resourceName] = element.innerText;
              break;
            case "bool":
              _bools[resourceName] = resourceValue.parseBool();
              break;
            case "int":
              _ints[resourceName] = int.parse(resourceValue);
              break;
            case "double":
              _doubles[resourceName] = double.parse(resourceValue);
              break;
            case "color":
              _colors[resourceName] = ColorExt.parse(resourceValue);
              break;
            default:
              throw Exception("Unknown resource type '$resourceType'");
          }
        }
      }
    }
  }

  String getString(String name) {
    final value = _strings[name];
    if (value != null) return value;
    throw Exception("String resource '$name' not found");
  }

  bool getBool(String name) {
    final value = _bools[name];
    if (value != null) return value;
    throw Exception("bool resource '$name' not found");
  }

  int getInt(String name) {
    final value = _ints[name];
    if (value != null) return value;
    throw Exception("int resource '$name' not found");
  }

  double getDouble(String name) {
    final value = _doubles[name];
    if (value != null) return value;
    throw Exception("double resource '$name' not found");
  }

  Color getColor(String name) {
    final value = _colors[name];
    if (value != null) return value;
    throw Exception("Color resource '$name' not found");
  }

  String getColorString(String name) {
    final color = getColor(name);
    return color.asString();
  }

  /// Updates values by parsing the given XML content.
  ///
  /// Used by the debug service extension to push live changes from
  /// the IDE without restarting the app. New values overwrite
  /// existing ones with the same name.
  void updateValues(String xml) {
    _parseValuesXml(xml);
  }
}

// =============================================================================
// FragmentResourceBundle
// =============================================================================

class FragmentResourceBundle extends ResourceBundle {
  final _fragments = <String, String>{};

  FragmentResourceBundle(super.pathSegment);

  @override
  Future<void> loadFromAssetBundle(
    String fileName,
    String resPath,
    String resName,
    String resExt,
    AssetBundle assetBundle,
  ) async {
    if (resExt == "xml") {
      final xml = await assetBundle.loadString(fileName);
      _fragments["$resPath$resName.$resExt"] = xml;
    }
  }

  @override
  void loadFromString(String resPath, String resName, String resExt, String content) {
    if (resExt == "xml") {
      _fragments["$resPath$resName.$resExt"] = content;
    }
  }

  /// Returns the raw XML string for the given fully-qualified name.
  String getFragmentRaw(String fqn) {
    final value = _fragments[fqn];
    if (value != null) return value;
    throw Exception(
      "Fragment resource '$fqn' not found. If the fragment name "
      "references a subdirectory, i.e. includes a forward slash ('/') in "
      "the name, please make sure to add the subdirectory to the 'assets' "
      "section in pubspec.yaml.",
    );
  }

  /// Updates a single fragment's raw XML content by fully-qualified name.
  ///
  /// Used by the debug service extension to push live changes from
  /// the IDE without restarting the app.
  void updateFragment(String fqn, String content) {
    _fragments[fqn] = content;
  }

  String getFragmentFqn(String name, [String? relativeTo]) {
    final fqn = _getFragmentFqn(name, relativeTo);
    if (fqn != null) return fqn;

    final relative = relativeTo != null ? " Tried looking relative to '$relativeTo'." : "";
    throw Exception(
      "Fragment resource '$name' not found.$relative If the "
      "fragment name references a subdirectory, i.e. includes a forward "
      "slash ('/') in the name, please make sure to add the subdirectory "
      "to the 'assets' section in pubspec.yaml.",
    );
  }

  String? _getFragmentFqn(String name, [String? relativeTo]) {
    if (!name.endsWith(".xml")) {
      return _getFragmentFqn("$name/index.xml", relativeTo) ??
          _getFragmentFqn("$name.xml", relativeTo);
    }
    if (_fragments.containsKey(name)) {
      return name;
    }
    if (isNotEmpty(relativeTo)) {
      final relativeName = Path.parseRelativeTo(name, relativeTo).toString();
      if (_fragments.containsKey(relativeName)) return relativeName;
    }
    return null;
  }
}
