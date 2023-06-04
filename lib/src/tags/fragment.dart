import 'package:xml/xml.dart';

import '../xwidget.dart';


class FragmentTag implements Tag {
  @override
  String get name => "fragment";

  @override
  Children? processTag( XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {
    // 'name' is a required attribute.
    final fragmentName = attributes["name"];
    if (fragmentName == null) {
      final dump = XWidget.dump(element, dependencies);
      throw Exception("<$name> 'name' attribute is required. $dump");
    }

    // inflate named fragment
    final inheritedAttributes = element.attributes.where((attribute) => attribute.localName != "name");
    final object = XWidget.inflateFragment(fragmentName, dependencies, inheritedAttributes: inheritedAttributes);
    if (object == null) return null;

    final children = Children();
    final attributeName = element.getAttribute("for");
    if (attributeName != null && attributeName.isNotEmpty) {
      children.attributes[attributeName] = object;
    } else {
      children.objects.add(object);
    }
    return children;
  }
}