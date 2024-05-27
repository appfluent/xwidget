import 'package:xml/xml.dart';

import '../../xwidget.dart';

/// A tag that renders a UI fragment
///
/// Supports folders, inherited attributes, and HTML style query parameters.
/// Parameters are stored as dependencies.
///
/// Attributes:
/// - name (required): name of the fragment to render i.e 'login' or
///        'login.xml'. You can prepend a path if you're using fragment
///         folders i.e. 'profile/login'.
/// - dependenciesScope (optional): Defines the method for passing Dependencies
///         to immediate children. Valid values are `new`, `copy`, and
///         `inherit`. The default is `inherit`.
/// - for (optional): name of parent attribute to render the fragment into.
///         ```dart
///         <AppBar>
///             <fragment for="leading" name="profile/login"/>
///         </AppBar>
///         ```
class FragmentTag implements Tag {
  static const attributeNames = {"for", "name", "visible"};

  @override
  String get name => "fragment";

  @override
  Children? processTag(
      XmlElement element,
      Map<String, dynamic> attributes,
      Dependencies dependencies
  ) {
    // 'name' is a required attribute.
    final String? fragmentName = attributes["name"];
    if (fragmentName == null) {
      final dump = XWidget.dump(element, dependencies);
      throw Exception("<$name> 'name' attribute is required. $dump");
    }

    final bool? visible = attributes["visible"];
    if (toBool(visible) == false) {
      // don't show fragment
      return null;
    }

    // process child tags for parameters only - need original deps here
    // todo: only allow processing of 'params', 'forEach', and 'if' elements
    final params = _onlyParams(XWidget.inflateXmlElementChildren(
        element,
        dependencies,
        excludeText: true
    ));

    // scope dependencies. if we're going to modify the dependencies via params,
    // then default the dependencies scope to 'copy'; otherwise default to
    // 'inherit'.
    final deps = XWidget.scopeDependencies(
        element,
        dependencies,
        attributes["dependenciesScope"],
        params.isNotEmpty || fragmentName.contains("?") ? "copy" : "inherit"
    );

    // inflate named fragment
    final object = XWidget.inflateFragment(fragmentName, deps, params: params,
        inheritedAttributes: element.attributes.where((attribute) {
          return !attributeNames.contains(attribute.localName);
        }),
    );
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

  //===================================
  // private methods
  //===================================

  Map<String, dynamic> _onlyParams(Children children) {
    final params = <String, dynamic>{};
    for (final child in children.objects) {
      if (child is MapEntry) {
        params[child.key] = child.value;
      }
    }
    return params;
  }
}
