import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/parsers.dart';
import '../utils/utils.dart';
import '../xwidget.dart';


class BuilderTag implements Tag {
  @override
  String get name => "builder";

  @override
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {

    // 'vars' max length is 5
    final vars = parseListOfStrings(element.getAttribute("vars"));
    if (vars != null && vars.length > 5) throw Exception("<$name> 'vars' attribute only accepts up to 5 variables");

    // 'for' is a required attribute.
    final forAttribute = element.getAttribute("for");
    if (forAttribute == null || forAttribute.isEmpty) throw Exception("<$name> 'for' attribute is required.");

    final multiChild = parseBool(attributes["multiChild"]) ?? false;
    final nullable = parseBool(attributes["nullable"]) ?? false;
    final copyDependencies = parseBool(attributes["copyDependencies"]) ?? false;

    dynamic builder([p0, p1, p2, p3, p4]) {
      final deps = copyDependencies ?  dependencies.copy() : dependencies;
      if (vars != null) {
        for (int paramIndex = 0; paramIndex < vars.length; paramIndex++) {
          final varName = vars[paramIndex];
          if (varName.isNotEmpty && !RegExp(r"^_*$").hasMatch(varName)) {
            switch (paramIndex) {
              case 0: if (p0 is! BuildContext) deps[varName] = p0; break;
              case 1: if (p1 is! BuildContext) deps[varName] = p1; break;
              case 2: if (p2 is! BuildContext) deps[varName] = p2; break;
              case 3: if (p3 is! BuildContext) deps[varName] = p3; break;
              case 4: if (p4 is! BuildContext) deps[varName] = p4; break;
            }
          }
        }
      }
      final children = XWidget.inflateXmlElementChildren(element, deps).objects;
      return multiChild ? children : getOnlyChild("<$name> tag", children);
    }

    List<Widget> multiWidgetBuilder([p0, p1, p2, p3, p4]) {
      return [...builder(p0, p1, p2, p3, p4)];
    }

    Widget singleWidgetBuilder([p0, p1, p2, p3, p4]) {
      return builder(p0, p1, p2, p3, p4);
    }

    Widget? nullableSingleWidgetBuilder([p0, p1, p2, p3, p4]) {
      return builder(p0, p1, p2, p3, p4);
    }

    final children = Children();
    if (multiChild) {
      children.attributes[forAttribute] = multiWidgetBuilder;
    } else if (nullable) {
      children.attributes[forAttribute] = nullableSingleWidgetBuilder;
    } else {
      children.attributes[forAttribute] = singleWidgetBuilder;
    }
    return children;
  }
}
