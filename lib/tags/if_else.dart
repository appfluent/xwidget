import 'package:xml/xml.dart';

import '../xwidget.dart';


class IfElseTag implements Tag {
  @override
  String get name => "if";

  @override
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {
    // 'test' is a required attribute
    if (!attributes.containsKey("test")) throw Exception("<$name> 'test' attribute is required.");

    final test = attributes["test"];
    final elementOrElse = _isTrue(test) ? element : _findElseElement(element);
    if (elementOrElse != null) {
      return XWidget.inflateXmlElementChildren(elementOrElse, dependencies, excludeElements: {"else"});
    }
    return null;
  }

  XmlElement? _findElseElement(XmlElement element) {
    final children = element.childElements;
    for (final child in children) {
      if (child.localName == "else") {
        return child;
      }
    }
    return null;
  }

  bool _isTrue(value) {
    return value is bool && value == true;
  }
}