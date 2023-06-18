import 'package:xml/xml.dart';

import '../xwidget.dart';

/// A tag that renders it's children to an attribute of its parent.
///
/// @deprecated Use the 'for' attribute on each inflater element instead.
class AttributeTag implements Tag {
  @override
  String get name => "attribute";

  @override
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {
    // 'name' is a required attribute.
    final attributeName = attributes["name"];
    if (attributeName == null) throw Exception("<$name> 'name' attribute is required.");

    final children = Children();
    final attributeChildren = XWidget.inflateXmlElementChildren(element, dependencies);
    if (attributeChildren.objects.length > 1) {
      // multiple objects were inflated, so set the attr value to the array
      children.attributes[attributeName] = attributeChildren.objects;
    } else if (attributeChildren.objects.length == 1) {
      // one object was inflated, so set the attr value to just the first object
      children.attributes[attributeName] = attributeChildren.objects[0];
    } else if (attributeChildren.text.isNotEmpty) {
      // we have some text items, so lets' join and parse them
      final text = attributeChildren.text.join();
      final value = XWidget.parseAttribute(
          attributeName: attributeName,
          attributeValue: text,
          dependencies: dependencies
      );
      if (value != null) {
        // successfully parsed the text value, so set it
        children.attributes[attributeName] = value;
      }
    }
    return children;
  }
}