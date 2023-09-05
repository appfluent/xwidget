import 'package:xml/xml.dart';

import '../xwidget.dart';

/// A pair of tags that conditionally render portions of the UI.
///
/// If the `test` expression evaluates to `true`, then <if>'s children are rendered, otherwise <else>'s children
/// are rendered. The `test` expression must return a bool, otherwise an [Exception] is thrown. The <else> tag
/// must be a direct child of an <if> tag, if present, otherwise it will be ignored.
///
/// <if> Attributes:
/// - test (required): A bool expression i.e. ${user.name == 'Mike'}
///
/// <else> Attributes: none
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
    for (final child in element.children) {
      if (child is XmlElement && child.localName == "else") {
        return child;
      }
    }
    return null;
  }

  bool _isTrue(value) {
    return value is bool && value == true;
  }
}
