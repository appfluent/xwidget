import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/parsers.dart';
import '../utils/utils.dart';
import '../xwidget.dart';
import 'async.dart';

typedef XWidgetControllerFactory<T extends Controller> = T Function();

class ControllerWidget extends StatefulWidget {
  final String name;
  final XmlElement element;
  final Dependencies dependencies;
  final Widget? errorWidget;
  final Widget? progressWidget;
  final Map<String, dynamic> options;

  ControllerWidget({
    super.key,
    required this.name,
    required this.element,
    required this.dependencies,
    this.errorWidget,
    this.progressWidget,
    Map<String, dynamic>? options,
  }): options = options ?? {};

  @override
  // ignore: no_logic_in_create_state
  Controller createState() => XWidget.createController(name.trim());
}

abstract class Controller extends State<ControllerWidget> {
  late final dynamic _initValue;

  @nonVirtual
  Dependencies get dependencies => widget.dependencies;

  @nonVirtual
  Map<String, dynamic> get options => widget.options;

  @override
  @nonVirtual
  void initState() {
    super.initState();
    _initValue = init();
  }

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    return DynamicBuilder(
      initializer: (_,__) => _initValue,
      builder: (_,deps,__) => _inflateChildren(deps),
      dependencies: widget.dependencies,
      errorWidget: widget.errorWidget,
      progressWidget: widget.progressWidget,
    );
  }

  dynamic init() {}

  void bindDependencies() {}

  //===================================
  // Private Methods
  //===================================

  Widget _inflateChildren(Dependencies dependencies) {
    bindDependencies();
    final children = XWidget.inflateXmlElementChildren(
      widget.element,
      dependencies,
      excludeText: true,
      excludeAttributes: true,
    );
    return XWidgetUtils.getOnlyChild("Controller", children.objects, const SizedBox.shrink());
  }
}

class ControllerWidgetInflater extends Inflater {
  @override
  String get type => 'Controller';

  @override
  bool get inflatesOwnChildren => true;

  @override
  bool get inflatesCustomWidget => true;

  @override
  ControllerWidget? inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text)
  {
    return ControllerWidget(
      key: attributes['key'],
      name: attributes['name'],
      element: attributes['_element'],
      dependencies: attributes['_dependencies'],
      errorWidget: attributes['errorWidget'],
      progressWidget: attributes['progressWidget'],
      options: attributes['options'] != null ? {...attributes['options']} : null,
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key': return parseKey(value);
      case 'name': return value;
      case 'errorWidget': break;
      case 'progressWidget': break;
      case 'options': break;
    }
    return value;
  }
}
