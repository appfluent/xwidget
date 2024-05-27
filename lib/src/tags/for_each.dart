import 'package:xml/xml.dart';

import '../utils/functions/converters.dart';
import '../xwidget.dart';

class ForEachTag implements Tag {
  @override
  String get name => "forEach";

  @override
  Children? processTag(
      XmlElement element,
      Map<String, dynamic> attributes,
      Dependencies dependencies)
  {
    // 'var' is a required attribute
    final varName = attributes["var"];
    if (varName == null || varName.isEmpty) {
      throw Exception("<$name> 'var' attribute is required.");
    }

    // 'items' is a required attribute
    final items = attributes["items"];
    if (items == null) return null;

    // check for iterable object
    final iterable = items is Map ? items.entries : items;
    if (iterable is! Iterable) {
      throw Exception("<$name> 'items' attribute does not reference an iterable object");
    }

    // 'indexVar' is an optional attribute
    final indexVarName = attributes["indexVar"];

    // 'groupSize' is an optional attribute
    final groupSize = toInt(attributes["groupSize"]) ?? 1;

    // 'dependenciesScope' is an optional attribute
    final dependenciesScope = attributes["dependenciesScope"];

    var index = 0;
    var itemGroup = [];
    final children = Children();

    for (final item in iterable) {
      dynamic depItem = item is MapEntry ? {"key": item.key, "value": item.value} : item;
      int depIndex = index ~/ groupSize;

      if (groupSize > 1) {
        itemGroup.add(depItem);
        depItem = itemGroup;
      }

      if ((index + 1) % groupSize == 0 || index == iterable.length - 1) {
        final deps = XWidget.scopeDependencies(element, dependencies, dependenciesScope, "copy");
        deps[varName] = depItem;
        if (indexVarName != null && indexVarName.isNotEmpty) {
          deps[indexVarName] = depIndex;
        }
        final tagChildren = XWidget.inflateXmlElementChildren(element, deps, excludeText: true);
        children.addAll(tagChildren);
        itemGroup = [];
      }
      index++;
    }
    return children;
  }
}
