import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/parsers.dart';
import '../utils/utils.dart';
import '../xwidget.dart';

/// A tag that wraps its children in a builder function.
///
/// This tag is extremely useful when the parent requires a builder function, such as
/// [PageView.builder](https://api.flutter.dev/flutter/widgets/PageView/PageView.builder.html).
/// Use `vars`, `multiChild`, and `nullable` attributes to configure the builder function's signature.
/// When the builder function executes, the values of named arguments defined in `vars` are stored
/// as dependencies in the current `Dependencies` instance. The values of placeholder arguments (_) are
/// simply ignored. The `BuildContext` is never stored as a dependency, even if explicitly named,
/// because it would cause a memory leak.
///
/// Attributes:
/// - for (required): The name of the parent attribute that will be assigned the builder function.
/// - vars (optional): A comma separated list of named and placeholder function arguments. Named arguments are added to
///       `Dependencies`. Supports up to five arguments.
/// - multiChild (optional): Whether the builder function should return an array or a single widget. Defaults to `false`.
/// - nullable (optional): Whether the builder function can return null. Defaults to `false`.
/// - dependenciesScope (optional): Defines the method for passing Dependencies to immediate children. Valid
///       values are `new`, `copy`, and `inherit`. The default is `inherit`.
///
/// Example:
/// ```xml
/// <PageView.builder>
///     <builder for="itemBuilder" vars="_,index" nullable="true">
///         <Container>
///           <Text data="${index}"/>
///         </Container>
///     </builder>
/// </PageView.builder>
/// ```
class BuilderTag implements Tag {
  static final RegExp _ignoreVar = RegExp(r"^_*$");

  @override
  String get name => "builder";

  @override
  Children? processTag(
      XmlElement element,
      Map<String, dynamic> attributes,
      Dependencies dependencies
  ) {
    // 'vars' max length is 5
    final vars = parseListOfStrings(element.getAttribute("vars"));
    if (vars != null && vars.length > 5){
      throw Exception("<$name> 'vars' attribute only accepts up to 5 variables");
    }

    // 'for' is a required attribute.
    final forAttribute = element.getAttribute("for");

    final multiChild = parseBool(attributes["multiChild"]) ?? false;
    final nullable = parseBool(attributes["nullable"]) ?? false;
    final dependenciesScope = attributes["dependenciesScope"];

    dynamic builder([p0, p1, p2, p3, p4]) {
      final params = <String, dynamic>{};
      if (vars != null) {
        for (int paramIndex = 0; paramIndex < vars.length; paramIndex++) {
          final varName = vars[paramIndex];
          if (CommonUtils.isNotBlank(varName) && !_ignoreVar.hasMatch(varName)) {
            switch (paramIndex) {
              case 0: if (p0 is! BuildContext) params[varName] = p0; break;
              case 1: if (p1 is! BuildContext) params[varName] = p1; break;
              case 2: if (p2 is! BuildContext) params[varName] = p2; break;
              case 3: if (p3 is! BuildContext) params[varName] = p3; break;
              case 4: if (p4 is! BuildContext) params[varName] = p4; break;
            }
          }
        }
      }
      final deps = XWidget.scopeDependencies(
          element,
          dependencies,
          dependenciesScope,
          params.isEmpty ? "inherit" : "copy"
      ).addAll(params);
      final children = XWidget.inflateXmlElementChildren(element, deps).objects;
      return multiChild ? children : XWidgetUtils.getOnlyChild("<$name> tag", children);
    }

    List<Widget> multiWidgetBuilder([p0, p1, p2, p3, p4]) {
      return [...builder(p0, p1, p2, p3, p4)];
    }

    Widget singleWidgetBuilder([p0, p1, p2, p3, p4]) {
      return builder(p0, p1, p2, p3, p4);
    }

    Widget? nullableSingleWidgetBuilder([p0, p1, p2, p3, p4]) {
      return builder(p0, p1, p2, p3, p4);
    }

    final children = Children();
    if (multiChild) {
      if (CommonUtils.isBlank(forAttribute)) {
        children.objects.add(multiWidgetBuilder);
      } else {
        children.attributes[forAttribute!] = multiWidgetBuilder;
      }
    } else if (nullable) {
      if (CommonUtils.isBlank(forAttribute)) {
        children.objects.add(nullableSingleWidgetBuilder);
      } else {
        children.attributes[forAttribute!] = nullableSingleWidgetBuilder;
      }
    } else {
      if (CommonUtils.isBlank(forAttribute)) {
        children.objects.add(singleWidgetBuilder);
      } else {
        children.attributes[forAttribute!] = singleWidgetBuilder;
      }
    }
    return children;
  }
}
