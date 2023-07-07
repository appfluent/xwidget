import 'package:xml/xml.dart';

import '../xwidget.dart';

/// A tag that renders a UI fragment
///
/// Supports folders, inherited attributes, and HTML style query parameters. Parameters are stored as dependencies.
///
/// Attributes:
/// - name (required): name of the fragment to render i.e 'login' or 'login.xml'. You can prepend a path if
///         if you're using fragment folders i.e. 'profile/login'.
/// - dependenciesScope (optional): Defines the method for passing Dependencies to immediate children. Valid
///         values are `new`, `copy`, and `inherit`. The default is `inherit`.
/// - for (optional): name of parent attribute to render the fragment into.
///         ```dart
///         <AppBar>
///             <fragment for="leading" name="profile/login"/>
///         </AppBar>
///         ```
class FragmentTag implements Tag {
  static const attributeNames = ["for", "name"];

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

    // 'dependenciesScope' is optional
    final dependenciesScope = attributes["dependenciesScope"];

    // inflate named fragment
    final deps = XWidget.scopeDependencies(dependencies, dependenciesScope);
    final inheritedAttributes = element.attributes.where((attribute) => !attributeNames.contains(attribute.localName));
    final object = XWidget.inflateFragment(fragmentName, deps, inheritedAttributes: inheritedAttributes);
    if (object == null) return null;

    final children = Children();
    final forAttribute = element.getAttribute("for");
    if (forAttribute != null && forAttribute.isNotEmpty) {
      children.attributes[forAttribute] = object;
    } else {
      children.objects.add(object);
    }
    return children;
  }
}