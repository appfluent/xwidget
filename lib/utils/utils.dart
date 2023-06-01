
import 'package:flutter/material.dart';

import '../xwidget.dart';

/// Gets the first child in a list of children or throws an [Exception] if there are multiple children.
///
/// The expected primary use for this method is by inflaters. We want inflaters to fail loudly if it can't render all
/// of its children. Silently rendering only the first child leads to UI bugs that are difficult to find.
dynamic getOnlyChild(String widgetName, List<dynamic> children, [dynamic defaultValue]) {
  if (children.isEmpty) return defaultValue;
  if (children.length > 1) throw Exception("'$widgetName' cannot have multiple children");
  return children[0];
}

bool isBlank(String? value) {
  return value == null || value.isEmpty;
}

bool isNotBlank(String? value) {
  return !isBlank(value);
}

int? tryParseInt(dynamic value, {int? radix}) {
  if (value is int) return value;
  return isNotBlank(value) ? int.tryParse(value!) : null;
}

Function createCallbackFunction({
  required Function onCallback,
  required Dependencies dependencies,
  List<String>? callbackVars,
  bool copyDependencies = false
}) {
  return ([p0, p1, p2, p3, p4]) {
    final deps = copyDependencies ? dependencies.copy() : dependencies;
    if (callbackVars != null) {
      for (int paramIndex = 0; paramIndex < callbackVars.length; paramIndex++) {
        final varName = callbackVars[paramIndex];
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
    return onCallback(deps);
  };
}
