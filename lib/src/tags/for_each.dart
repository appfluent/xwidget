import 'package:xml/xml.dart';

import '../xwidget.dart';

class ForEachTag implements Tag {
  @override
  String get name => "forEach";

  @override
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {
    // 'var' is a required attribute
    final varName = attributes["var"];
    if (varName == null || varName.isEmpty) throw Exception("<$name> 'var' attribute is required.");

    // 'items' is a required attribute
    final items = attributes["items"];
    if (items == null) return null;

    // check for iterable object
    final iterable = items is Map ? items.entries : items;
    if (iterable is! Iterable) throw Exception("<$name> 'items' attribute does not reference an iterable object");

    // 'indexVar' is an optional attribute
    final indexVarName = attributes["indexVar"];

    // 'dependenciesScope' is an optional attribute
    final dependenciesScope = attributes["dependenciesScope"];

    var indexVar = 0;
    final children = Children();
    for (final item in iterable) {
      final deps = XWidget.scopeDependencies(dependencies, dependenciesScope);
      deps[varName] = item is MapEntry ? {"key": item.key, "value": item.value} : item;
      if (indexVarName != null && indexVarName.isNotEmpty) {
        deps[indexVarName] = indexVar;
      }
      final tagChildren = XWidget.inflateXmlElementChildren(element, deps);
      children.addAll(tagChildren);
      indexVar++;
    }
    return children;
  }
}
