import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:xwidget_el/xwidget_el.dart';

import '../router/xrouter.dart';
import '../extensions.dart';
import 'resources.dart';

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
      _parseXml(xml);
    }
  }

  @override
  void loadFromString(String resPath, String resName, String resExt, String content) {
    if (resExt == "xml") {
      _parseXml(content);
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
    _parseXml(xml);
  }

  void _parseXml(String xml) {
    final document = XmlDocument.parse(xml);
    final root = document.rootElement;
    switch (root.name.local) {
      case "resources":
        _processValues(root);
      case "routes":
        XRouter.loadRoutesFromXml("source", document);
    }
  }

  void _processValues(XmlElement root) {
    for (final element in root.childElements) {
      final resourceType = element.name.local;
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

mixin ValueResourceMixin {
  String getString(String name) => _values.getString(name);
  bool getBool(String name) => _values.getBool(name);
  int getInt(String name) => _values.getInt(name);
  double getDouble(String name) => _values.getDouble(name);
  Color getColor(String name) => _values.getColor(name);
  String getColorString(String name) => _values.getColorString(name);

  ValueResourceBundle get _values {
    return Resources.of<ValueResourceBundle>();
  }
}
