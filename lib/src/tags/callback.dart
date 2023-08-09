import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/parsers.dart';
import '../xwidget.dart';

/// This tag allows you to bind an event handler with custom arguments. If you don't need to pass any
/// arguments, then just bind the handler using EL, like so: `<TextButton onPressed="${onPressed}"/>`.
/// This is sufficient in most cases.
///
/// The `callback` tag creates an event handler function for you and executes the `action` when the
/// event is triggered. `action` is an EL expression that is evaluated at the time of the event. Do not
/// enclose the expression in curly braces `${...}`, otherwise it will be evaluated immediately upon
/// creation instead of when the event is fired.
///
/// If the handler function defines arguments in its signature, you must declare those arguments using
/// the `vars` attribute. This attribute takes a comma separated list of argument names. When the
/// handler is triggered, argument values are added to `Dependencies` using the specified name as the
/// key, and can be referenced in the `action` EL expression, if needed. They're also accessible
/// anywhere else that instance of `Dependencies` is available. If you don't need the values, then use
/// and underscore (_) in place of the name. This will ignore those value and they won't be added to
/// `Dependencies` e.g. `...vars="_,index"...`. `BuildContext` is never added to `Dependencies` even
/// when named, because this would cause a memory leak.
class CallbackTag implements Tag {
  static final RegExp _ignoreVar = RegExp(r"^_*$");

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

    // 'dependenciesScope' is optional
    final dependenciesScope = attributes["dependenciesScope"];

    dynamic callback([p0, p1, p2, p3, p4]) {
      final deps = XWidget.scopeDependencies(dependencies, dependenciesScope);
      if (vars != null) {
        for (int paramIndex = 0; paramIndex < vars.length; paramIndex++) {
          final varName = vars[paramIndex];
          if (varName.isNotEmpty && !_ignoreVar.hasMatch(varName)) {
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
      final value = XWidget.parseExpression(action, dependencies);
      if (returnVar != null && returnVar.isNotEmpty) {
        deps.setValue(returnVar, value);
      }
    }

    final children = Children();
    children.attributes[forAttribute] = callback;
    return children;
  }
}