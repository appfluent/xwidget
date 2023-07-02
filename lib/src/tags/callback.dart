import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/parsers.dart';
import '../xwidget.dart';

class CallbackTag implements Tag {
  @override
  String get name => "callback";

  @override
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {

    // 'for' is a required attribute.
    final forAttribute = element.getAttribute("for");
    if (forAttribute == null || forAttribute.isEmpty) throw Exception("<$name> 'for' attribute is required.");

    // 'vars' max length is 5
    final vars = parseListOfStrings(element.getAttribute("vars"));
    if (vars != null && vars.length > 5) throw Exception("<$name> 'vars' attribute only accepts up to 5 variables");

    // 'action' is a required attribute
    final action = element.getAttribute("action");
    if (action == null || action.isEmpty) throw Exception("<$name> 'action' attribute is required");

    // 'returnVar' is optional
    final returnVar = element.getAttribute("returnVar");

    // 'copyDependencies' is optional
    final copyDependencies = parseBool(attributes["copyDependencies"]) ?? false;

    dynamic callback([p0, p1, p2, p3, p4]) {
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
      final result = XWidget.parseExpression(dependencies, action);
      if (result.isSuccess) {
        final value = result.value.evaluate();
        if (returnVar != null && returnVar.isNotEmpty) {
          deps.setValue(returnVar, value);
        }
      } else {
        throw Exception("Failed to parse callback action: '$action'. ${result.message}");
      }
    }

    final children = Children();
    children.attributes[forAttribute] = callback;
    return children;
  }
}