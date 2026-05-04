import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:xwidget_el/xwidget_el.dart';

import '../path.dart';
import '../xml.dart';
import 'resources.dart';

class FragmentResourceBundle extends ResourceBundle {
  final _fragments = <String, String>{};
  final _fragmentCache = <String, XmlDocument>{};

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

  /// Clears the parsed XML cache. Safe to call when caching is
  /// disabled.
  void clearFragmentCache() {
    _fragmentCache.clear();
  }

  /// Updates a single fragment's raw XML content by fully-qualified name.
  ///
  /// Used by the debug service extension to push live changes from
  /// the IDE without restarting the app.
  void updateFragment(String fqn, String content) {
    _fragments[fqn] = content;
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

  /// Returns the parsed [XmlDocument] for the given fully-qualified
  /// fragment name. Uses the internal cache when enabled.
  XmlDocument getFragment(String fqn) {
    final cached = _fragmentCache[fqn];
    if (cached != null) return cached;

    final xmlString = getFragmentRaw(fqn);
    final doc = XmlParser.parse(SourceCode(xmlString, filePath: fqn, withPosition: true));
    _fragmentCache[fqn] = doc;
    return doc;
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

mixin FragmentResourceMixin {
  /// Clears the parsed XML cache. Safe to call when caching is
  /// disabled.
  void clearFragmentCache() {
    final bundle = Resources.of<FragmentResourceBundle>();
    bundle.clearFragmentCache();
  }

  /// Returns the parsed [XmlDocument] for the given fully-qualified
  /// fragment name. Uses the internal cache when enabled.
  XmlDocument getFragment(String fqn) {
    final bundle = Resources.of<FragmentResourceBundle>();
    return bundle.getFragment(fqn);
  }

  /// Resolves a fragment name to its fully-qualified path.
  String getFragmentFqn(String name, [String? relativeTo]) {
    final bundle = Resources.of<FragmentResourceBundle>();
    return bundle.getFragmentFqn(name, relativeTo);
  }
}
