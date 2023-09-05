import 'package:xml/xml.dart';

import '../xwidget.dart';

class VariableTag implements Tag {
  @override
  String get name => "var";

  @override
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {
    // 'name' is a required attribute
    final varName = attributes["name"];
    if (varName == null || varName.isEmpty) throw Exception("<$name> 'name' attribute is required.");

    // 'value' is a required attribute - check element attributes because the value could be null.
    if (element.getAttribute("value") == null) throw Exception("<$name> 'value' attribute is required.");

    // set data value and exit
    final value = attributes["value"];
    if (varName == "...") {
      if (value is Map<String, dynamic>) {
        dependencies.addAll(value);
      } else {
        throw Exception("Invalid type '${value.runtimeType}' for spread operator. "
            "Expected 'Data' or 'Map<String, dynamic>'.");
      }
    } else {
      dependencies.setValue(varName, value);
    }

    return null;
  }
}
