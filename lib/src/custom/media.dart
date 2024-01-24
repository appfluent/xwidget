import 'dart:core';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:xwidget/xwidget.dart';


class MediaQueryWidget extends StatelessWidget {
  final XmlElement element;
  final Dependencies dependencies;
  final String varName;
  final int smallMaxWidth;
  final int mediumMaxWidth;
  final String? dependenciesScope;

  const MediaQueryWidget({
    super.key,
    required this.element,
    required this.dependencies,
    this.varName = "mediaQuery",
    this.smallMaxWidth = 640,
    this.mediumMaxWidth = 1024,
    this.dependenciesScope
  });

  @override
  Widget build(BuildContext context) {
    final deps = XWidget.scopeDependencies(element, dependencies, dependenciesScope, "copy");
    final query = MediaQuery.of(context);

    final size = query.size;
    deps.setValue("$varName.size.width", size.width);
    deps.setValue("$varName.size.height", size.height);
    deps.setValue("$varName.size.layout", (size.width <= smallMaxWidth)
        ? "small" : (size.width <= mediumMaxWidth) ? "medium" : "large");

    final viewInsets = query.viewInsets;
    deps.setValue("$varName.viewInsets.horizontal", viewInsets.horizontal);
    deps.setValue("$varName.viewInsets.vertical", viewInsets.vertical);
    deps.setValue("$varName.viewInsets.eft", viewInsets.left);
    deps.setValue("$varName.viewInsets.top", viewInsets.top);
    deps.setValue("$varName.viewInsets.right", viewInsets.right);
    deps.setValue("$varName.viewInsets.bottom", viewInsets.bottom);

    final viewPadding = query.viewPadding;
    deps.setValue("$varName.viewPadding.horizontal", viewPadding.horizontal);
    deps.setValue("$varName.viewPadding.vertical", viewPadding.vertical);
    deps.setValue("$varName.viewPadding.left", viewPadding.left);
    deps.setValue("$varName.viewPadding.top", viewPadding.top);
    deps.setValue("$varName.viewPadding.right", viewPadding.right);
    deps.setValue("$varName.viewPadding.bottom", viewPadding.bottom);

    deps.setValue("$varName.boldText", query.boldText);
    deps.setValue("$varName.platformBrightness", query.platformBrightness);
    deps.setValue("$varName.orientation", query.orientation.name);
    deps.setValue("$varName.highContrast", query.highContrast);
    deps.setValue("$varName.disableAnimations", query.disableAnimations);

    final children = XWidget.inflateXmlElementChildren(element, deps, excludeText: true);
    return XWidgetUtils.getOnlyChild("MediaQuery", children.objects);
  }
}

class MediaQueryWidgetInflater extends Inflater {
  @override
  String get type => 'MediaQuery';

  @override
  bool get inflatesOwnChildren => true;

  @override
  bool get inflatesCustomWidget => true;

  @override
  MediaQueryWidget? inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text)
  {
    return MediaQueryWidget(
      key: attributes['key'],
      element: attributes['_element'],
      dependencies: attributes['_dependencies'],
      varName: attributes['varName'] ?? "mediaQuery",
      smallMaxWidth: attributes['smallMaxWidth'] ?? 640,
      mediumMaxWidth: attributes['mediumMaxWidth'] ?? 1024,
      dependenciesScope: attributes["dependenciesScope"],
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key': return parseKey(value);
      case 'varName': break;
      case 'smallMaxWidth': return int.parse(value);
      case 'mediumMaxWidth': return int.parse(value);
      case 'dependenciesScope': break;
    }
    return value;
  }
}