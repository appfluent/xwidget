import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';
import 'package:xwidget_el/xwidget_el.dart';

import '../analytics/analytics.dart';
import 'bundle/bundle_cache.dart';
import 'hash.dart';
import 'extensions.dart';
import 'path.dart';
import 'version.dart';

final _log = Logger('Resources');

class Resources {
  static final instance = Resources();
  static const _defaultFragmentsPath = 'resources/fragments';
  static const _defaultValuesPath = 'resources/values';
  static const _defaultDownloadTimeout = Duration(seconds: 15);
  static const _contentBaseUrl = String.fromEnvironment(
    'XWIDGET_CONTENT_URL',
    defaultValue: 'https://content.xwidget.dev',
  );

  final _resourceBundlesByType = <Type, ResourceBundle>{};
  final _resourceBundlesByPath = <String, ResourceBundle>{};

  static T of<T extends ResourceBundle>() {
    final bundle = instance._resourceBundlesByType[T];
    if (bundle != null) return bundle as T;
    throw Exception("Resource bundle of type '$T' not found");
  }

  /// Loads resources from local assets or from the XWidget Cloud content server.
  ///
  /// If [storageKey] is provided, resources are fetched from the content server.
  /// [projectId] is required when [storageKey] is provided.
  /// [channel] is required when [storageKey] is provided.
  /// [version] is required when [storageKey] is provided.
  ///
  /// If [storageKey] is null, resources are loaded from the local asset
  /// bundle using [fragmentsPath] and [valuesPath] to locate the files.
  Future<void> loadResources({
    String? fragmentsPath,
    String? valuesPath,
    String? projectKey,
    String? storageKey,
    String? channel,
    String? version,
    Duration? downloadTimeout,
    AssetBundle? assetBundle,
  }) async {
    fragmentsPath ??= _defaultFragmentsPath;
    valuesPath ??= _defaultValuesPath;
    downloadTimeout ??= _defaultDownloadTimeout;

    // Validate cloud resource requirements
    if (storageKey != null) {
      final missing = [
        if (projectKey == null) 'projectKey',
        if (channel == null) 'channel',
        if (version == null) 'version',
      ];
      if (missing.isNotEmpty) {
        throw ArgumentError("'${missing.join("', '")}' required when 'storageKey' is provided.");
      }
    } else if (projectKey != null && version == null) {
      throw ArgumentError("'version' is required when 'projectKey' is provided.");
    }

    // Initialize analytics if projectKey is provided — works with or
    // without cloud resources. Uses 'local' as channel when no
    // storageKey is provided.
    if (projectKey != null) {
      await Analytics.initialize(
        projectKey: projectKey,
        channel: channel ?? 'local',
        version: version!,
      );
    }

    // Load resources
    if (storageKey != null) {
      await _loadCloudResources(
        fragmentsPath: fragmentsPath,
        valuesPath: valuesPath,
        storageKey: storageKey,
        channel: channel!,
        version: version!,
        downloadTimeout: downloadTimeout,
      );
    } else {
      await _loadLocalResources(
        fragmentsPath: fragmentsPath,
        valuesPath: valuesPath,
        assetBundle: assetBundle,
      );
    }
  }

  /// Registers custom [ResourceBundle] instances for use with
  /// [Resources.of].
  ///
  /// Use this to register custom bundle types that handle additional
  /// resource categories beyond the built-in fragments and values.
  ///
  /// Throws an [Exception] if a bundle of the same type or path segment
  /// is already registered. Use [replaceResourceBundles] to overwrite
  /// existing bundles.
  void addResourceBundles(List<ResourceBundle> bundles) {
    for (final bundle in bundles) {
      if (_resourceBundlesByType.containsKey(bundle.runtimeType)) {
        throw Exception(
          "Resource bundle of type '${bundle.runtimeType}' "
          "handling path segment '${bundle.pathSegment}' conflicts with an "
          "existing bundle of the same type. Use "
          "'replaceResourceBundles(List<ResourceBundle>)' to replace "
          "existing bundles.",
        );
      }
      if (_resourceBundlesByPath.containsKey(bundle.pathSegment)) {
        throw Exception(
          "Resource bundle of type '${bundle.runtimeType}' "
          "handling path segment '${bundle.pathSegment}' conflicts with "
          "an existing bundle handling the same path. Use "
          "'replaceResourceBundles(List<ResourceBundle>)' to replace "
          "existing bundles.",
        );
      }

      _resourceBundlesByType[bundle.runtimeType] = bundle;
      _resourceBundlesByPath[bundle.pathSegment] = bundle;
    }
  }

  /// Registers [ResourceBundle] instances, replacing any existing bundles
  /// that conflict by type or path segment.
  ///
  /// This is used internally to load freshly parsed bundles from local
  /// assets or cloud archives. It can also be used to hot-swap custom
  /// bundles at runtime.
  void replaceResourceBundles(List<ResourceBundle> bundles) {
    for (final bundle in bundles) {
      // remove conflicting types
      final removedByType = _resourceBundlesByType.remove(bundle.runtimeType);
      if (removedByType != null) {
        _resourceBundlesByPath.remove(removedByType.pathSegment);
      }

      // remove conflicting paths
      final removedByPath = _resourceBundlesByPath.remove(bundle.pathSegment);
      if (removedByPath != null) {
        _resourceBundlesByType.remove(removedByPath.runtimeType);
      }

      _resourceBundlesByType[bundle.runtimeType] = bundle;
      _resourceBundlesByPath[bundle.pathSegment] = bundle;
    }
  }

  // ===========================================================================
  // Local resource loading
  // ===========================================================================

  Future<void> _loadLocalResources({
    required String fragmentsPath,
    required String valuesPath,
    AssetBundle? assetBundle,
  }) async {
    _log.info(
      'Loading local resources from fragmentsPath=$fragmentsPath, '
      'valuesPath=$valuesPath',
    );

    final activeAssetBundle = assetBundle ?? rootBundle;
    final manifestMap = await _loadManifest(activeAssetBundle);

    final fragments = FragmentResources(fragmentsPath);
    final values = ValueResources(valuesPath);

    var fragmentCount = 0;
    var valueFileCount = 0;

    for (final fileName in manifestMap.keys) {
      if (fileName.startsWith('$fragmentsPath/')) {
        final relativePath = fileName.substring(fragmentsPath.length + 1);
        final parts = _splitFileName(relativePath);
        if (parts != null) {
          await fragments.loadFromAssetBundle(
            fileName,
            parts.path,
            parts.name,
            parts.ext,
            activeAssetBundle,
          );
          fragmentCount++;
        }
      } else if (fileName.startsWith('$valuesPath/')) {
        final relativePath = fileName.substring(valuesPath.length + 1);
        final parts = _splitFileName(relativePath);
        if (parts != null) {
          await values.loadFromAssetBundle(
            fileName,
            parts.path,
            parts.name,
            parts.ext,
            activeAssetBundle,
          );
          valueFileCount++;
        }
      }
    }

    replaceResourceBundles([fragments, values]);
    _log.info(
      'Local resources loaded: $fragmentCount fragments, '
      '$valueFileCount value files',
    );
  }

  Future<dynamic> _loadManifest(AssetBundle assetBundle) async {
    try {
      final data = await assetBundle.load('AssetManifest.bin');
      return const StandardMessageCodec().decodeMessage(data);
    } catch (_) {
      final jsonStr = await assetBundle.loadString('AssetManifest.json');
      return json.decode(jsonStr);
    }
  }

  // ===========================================================================
  // Cloud resource loading
  // ===========================================================================

  Future<void> _loadCloudResources({
    required String fragmentsPath,
    required String valuesPath,
    required String storageKey,
    required String channel,
    required String version,
    required Duration downloadTimeout,
  }) async {
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
      _loadFromArchive(bundleBytes, fragmentsPath, valuesPath);
    } else {
      _log.info('No cached bundle available, falling back to local assets');
      await _loadLocalResources(fragmentsPath: fragmentsPath, valuesPath: valuesPath);
    }
  }

  void _loadFromArchive(Uint8List bytes, String fragmentsPath, String valuesPath) {
    final gzBytes = GZipDecoder().decodeBytes(bytes);
    final archive = TarDecoder().decodeBytes(gzBytes);

    final fragments = FragmentResources(fragmentsPath);
    final values = ValueResources(valuesPath);

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
          final parts = _splitFileName(relativePath);
          if (parts != null) {
            final content = utf8.decode(file.content as List<int>);
            fragments.loadFromString(parts.path, parts.name, parts.ext, content);
            fragmentCount++;
          }
        } else if (name.startsWith(valPrefix)) {
          final relativePath = name.substring(valPrefix.length);
          final parts = _splitFileName(relativePath);
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

  /// Splits a relative file path into its directory path, file name, and
  /// extension components.
  ///
  /// For example, `subdir/my_file.xml` returns
  /// `(path: "subdir/", name: "my_file", ext: "xml")`.
  static _FileNameParts? _splitFileName(String relativePath) {
    final lastSlash = relativePath.lastIndexOf('/');
    final lastDot = relativePath.lastIndexOf('.');

    if (lastDot < 0) return null; // no extension

    final path = lastSlash >= 0 ? relativePath.substring(0, lastSlash + 1) : '';
    final name = relativePath.substring(lastSlash + 1, lastDot);
    final ext = relativePath.substring(lastDot + 1);

    if (name.isEmpty || ext.isEmpty) return null;

    return _FileNameParts(path: path, name: name, ext: ext);
  }
}

class _FileNameParts {
  final String path;
  final String name;
  final String ext;

  _FileNameParts({required this.path, required this.name, required this.ext});
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
// ValueResources
// =============================================================================

class ValueResources extends ResourceBundle {
  final _strings = <String, String>{};
  final _bools = <String, bool>{};
  final _ints = <String, int>{};
  final _doubles = <String, double>{};
  final _colors = <String, Color>{};

  ValueResources(super.pathSegment);

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
}

extension ValueResourceExt on Resources {
  String getString(String name) {
    return Resources.of<ValueResources>().getString(name);
  }

  bool getBool(String name) {
    return Resources.of<ValueResources>().getBool(name);
  }

  int getInt(String name) {
    return Resources.of<ValueResources>().getInt(name);
  }

  double getDouble(String name) {
    return Resources.of<ValueResources>().getDouble(name);
  }

  Color getColor(String name) {
    return Resources.of<ValueResources>().getColor(name);
  }

  String getColorString(String name) {
    return Resources.of<ValueResources>().getColorString(name);
  }
}

// =============================================================================
// FragmentResources
// =============================================================================

class FragmentResources extends ResourceBundle {
  final _fragments = <String, String>{};

  FragmentResources(super.pathSegment);

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

  String getFragment(String fqn) {
    final value = _fragments[fqn];
    if (value != null) return value;
    throw Exception(
      "Fragment resource '$fqn' not found. If the fragment name "
      "references a subdirectory, i.e. includes a forward slash ('/') in "
      "the name, please make sure to add the subdirectory to the 'assets' "
      "section in pubspec.yaml.",
    );
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

extension FragmentResourcesExt on Resources {
  String getFragment(String fqn) {
    return Resources.of<FragmentResources>().getFragment(fqn);
  }

  String getFragmentFqn(String name, [String? relativeTo]) {
    return Resources.of<FragmentResources>().getFragmentFqn(name, relativeTo);
  }
}
