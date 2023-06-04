import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:xml/xml.dart';

import 'extensions.dart';
import 'path.dart';
import 'utils.dart';

class Resources {
  static final instance = Resources()..addResourceBundles([
    ValueResources("values"),
    FragmentResources("fragments")
  ]);

  final _resourceBundlesByType = <Type, ResourceBundle>{};
  final _resourceBundlesByPath = <String, ResourceBundle>{};

  static T of<T extends ResourceBundle>() {
    final bundle = instance._resourceBundlesByType[T];
    if (bundle != null) return bundle as T;
    throw Exception("Resource bundle of type '$T' not found");
  }

  void addResourceBundles(List<ResourceBundle> bundles) {
    for (final bundle in bundles) {
      if (_resourceBundlesByType.containsKey(bundle.runtimeType)) {
        throw Exception("Resource bundle of type '${bundle.runtimeType}' handling path segment ${bundle.pathSegment} "
            "conflicts with an existing bundle of the same type. Use 'replaceResourceBundles(List<ResourceBundle>)' "
            "to replace existing bundles.");
      }
      if (_resourceBundlesByPath.containsKey(bundle.pathSegment)) {
        throw Exception("Resource bundle of type '${bundle.runtimeType}' handling path segment ${bundle.pathSegment} "
            "conflicts with an existing bundle handling the same path. Use 'replaceResourceBundles(List<ResourceBundle>)' "
            "to replace existing bundles.");
      }

      // add new bundle
      _resourceBundlesByType[bundle.runtimeType] = bundle;
      _resourceBundlesByPath[bundle.pathSegment] = bundle;
    }
  }

  void replaceResourceBundles(List<ResourceBundle> bundles) {
    for (final bundle in bundles) {

      // remove conflicting types
      final removedByType = _resourceBundlesByType.remove(bundles.runtimeType);
      if (removedByType != null) _resourceBundlesByPath.remove(removedByType.pathSegment);

      // remove conflicting paths
      final removedByPath = _resourceBundlesByPath.remove(bundle.pathSegment);
      if (removedByPath != null) _resourceBundlesByType.remove(removedByPath.runtimeType);

      // add new bundle
      _resourceBundlesByType[bundle.runtimeType] = bundle;
      _resourceBundlesByPath[bundle.pathSegment] = bundle;
    }
  }

  Future<void> loadResources(String rootPath) async {
    final resRegExp = RegExp(
        r'^' '$rootPath' r'/((?<res>([a-zA-Z0-9_]+))/){0,1}(?<path>([a-zA-Z0-9_]+/)*)'
        r'(?<name>[a-zA-Z0-9_]+).(?<ext>[a-zA-Z0-9_]+)'
    );
    final manifest = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifest);
    for (final fileName in manifestMap.keys) {
      final match = resRegExp.firstMatch(fileName);
      if (match != null) {
        final res = match.namedGroup("res") ?? "";
        final resPath = match.namedGroup("path") ?? "";
        final resName = match.namedGroup("name") ?? "";
        final resExt = match.namedGroup("ext") ?? "";
        final bundle = _resourceBundlesByPath[res];
        if (bundle != null) {
          bundle.loadResources(fileName, resPath, resName, resExt);
        }
      }
    }
  }
}

abstract class ResourceBundle {
  final String pathSegment;

  ResourceBundle(this.pathSegment);

  Future<void> loadResources(String fileName, String resPath, String resName, String resExt);
}

//=====================================
// ValueResources
//=====================================

class ValueResources extends ResourceBundle {
  final _strings = <String, String>{};
  final _bools = <String, bool>{};
  final _ints = <String, int>{};
  final _doubles = <String, double>{};
  final _colors = <String, Color>{};

  ValueResources(super.pathSegment);

  @override
  Future<void> loadResources(String fileName, String resPath, String resName, String resExt) async {
    if (resExt == "xml") {
      final xml = await rootBundle.loadString(fileName);
      final document = XmlDocument.parse(xml);
      final root = document.getElement("resources");
      if (root != null) {
        for (final element in root.childElements) {
          final resourceType = element.name.qualified;
          final resourceName = element.getAttribute("name");
          final resourceValue = element.text.trim();
          if (resourceName != null && resourceValue.isNotEmpty) {
            switch (resourceType) {
              case "string":
                _strings[resourceName] = element.text;
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
  String getString(String name) => Resources.of<ValueResources>().getString(name);

  bool getBool(String name) => Resources.of<ValueResources>().getBool(name);

  int getInt(String name) => Resources.of<ValueResources>().getInt(name);

  double getDouble(String name) => Resources.of<ValueResources>().getDouble(name);

  Color getColor(String name) => Resources.of<ValueResources>().getColor(name);

  String getColorString(String name) => Resources.of<ValueResources>().getColorString(name);
}

//=====================================
// FragmentResources
//=====================================

class FragmentResources extends ResourceBundle {
  final _fragments = <String, String>{};

  FragmentResources(super.pathSegment);

  @override
  Future<void> loadResources(String fileName, String resPath, String resName, String resExt) async {
    if (resExt == "xml") {
      final xml = await rootBundle.loadString(fileName);
      _fragments["$resPath$resName.$resExt"] = xml;
    }
  }

  String getFragment(String fqn) {
    final value = _fragments[fqn];
    if (value != null) return value;
    throw Exception("Fragment resource '$fqn' not found. If the fragment name references a subdirectory, "
        "i.e. includes a forward slash ('/') in the name, please make sure to add the subdirectory to the "
        "'assets' section in pubspec.yaml.");
  }

  String getFragmentFqn(String name, [String? relativeTo]) {
    final fqn = _getFragmentFqn(name, relativeTo);
    if (fqn != null) return fqn;
    throw Exception("Fragment resource '$name' not found. Tried looking relative to '$relativeTo'. If the fragment name"
        " references a subdirectory, i.e. includes a forward slash ('/') in the name, please make sure to add the"
        " subdirectory to the 'assets' section in pubspec.yaml.");
  }

  String? _getFragmentFqn(String name, [String? relativeTo]) {
    if (!name.endsWith(".xml")) {
      return _getFragmentFqn("$name/index.xml", relativeTo) ?? _getFragmentFqn("$name.xml", relativeTo);
    }
    if (_fragments.containsKey(name)) {
      return name;
    }
    if (isNotBlank(relativeTo)) {
      final relativeName = Path.parseRelativeTo(name, relativeTo).toString();
      if (_fragments.containsKey(relativeName)) return relativeName;
    }
    return null;
  }
}

extension FragmentResourcesExt on Resources {
  String getFragment(String fqn) => Resources.of<FragmentResources>().getFragment(fqn);

  String getFragmentFqn(String name, [String? relativeTo]) => Resources.of<FragmentResources>().getFragmentFqn(name, relativeTo);
}