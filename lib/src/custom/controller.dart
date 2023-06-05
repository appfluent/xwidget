import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/parsers.dart';
import '../utils/utils.dart';
import '../xwidget.dart';
import 'async.dart';


typedef XWidgetControllerFactory<T extends Controller> = T Function();

@InflaterDef(inflaterType: "Controller", inflatesOwnChildren: true)
class ControllerWidget extends StatefulWidget {
  final String name;
  final XmlElement element;
  final Dependencies dependencies;
  final Widget? errorWidget;
  final Widget? progressWidget;

  @override
  ControllerWidgetState createState() => ControllerWidgetState();

  const ControllerWidget({
    Key? key,
    required this.name,
    required this.element,
    required this.dependencies,
    this.errorWidget,
    this.progressWidget,
  }) : super(key: key);
}

class ControllerWidgetState extends State<ControllerWidget> {
  late final Controller _controller;
  late final dynamic _initValue;

  @override
  void initState() {
    super.initState();
    _controller = XWidget.createController(widget.name);
    _controller._mountedProvider = _getMounted;
    _controller._contextProvider = _getContext;
    _controller._dependenciesProvider = _getDependencies;
    _controller._setStateProvider = setState;
    _initValue = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicBuilder(
      initializer: _initializer,
      builder: _builder,
      dependencies: widget.dependencies,
      errorWidget: widget.errorWidget,
      progressWidget: widget.progressWidget,
    );
  }

  //===================================
  // Private Methods
  //===================================

  /// Returns the initValue received from [Controller.initialize].
  ///
  /// [Controller.initialize] is called in [setState] instead of being passed directly to [DynamicBuilder]
  /// as the initializer function because we don't want to reinitialize the controller every time the
  /// widget's 'build' function is called.
  dynamic _initializer(BuildContext context, Dependencies dependencies) {
    return _initValue;
  }

  Widget _builder(BuildContext context, Dependencies dependencies, dynamic initValue) {
    if (_controller.shouldBuild()) {
      _controller.bindDependencies();
      final children = XWidget.inflateXmlElementChildren(widget.element, dependencies);
      return XWidgetUtils.getOnlyChild("Controller", children.objects, const SizedBox.shrink());
    }
    return const SizedBox.shrink();
  }

  bool _getMounted() => mounted;

  BuildContext _getContext() => context;

  Dependencies _getDependencies() => widget.dependencies;
}

abstract class Controller extends WidgetsBindingObserver {

  @nonVirtual
  bool get mounted => _mountedProvider();

  @nonVirtual
  BuildContext get context => _contextProvider();

  @nonVirtual
  Dependencies get dependencies => _dependenciesProvider();

  @nonVirtual
  void setState(VoidCallback function) => _setStateProvider(function);

  bool shouldBuild() => true;

  dynamic initialize() {}

  void bindDependencies() {}

  dispose() {}

  //===================================
  // private methods
  //===================================

  @nonVirtual
  late final bool Function() _mountedProvider;

  @nonVirtual
  late final BuildContext Function() _contextProvider;

  @nonVirtual
  late final Dependencies Function() _dependenciesProvider;

  @nonVirtual
  late final void Function(VoidCallback) _setStateProvider;
}

class ControllerWidgetInflater extends Inflater {

  @override
  String get type => 'Controller';

  @override
  bool get inflatesOwnChildren => true;

  @override
  bool get inflatesCustomWidget => true;

  @override
  ControllerWidget? inflate(Map<String, dynamic> attributes, List<dynamic> children, String? text) {
    return ControllerWidget(
      key: attributes['key'],
      name: attributes['name'],
      element: attributes['_element'],
      dependencies: attributes['_dependencies'],
      errorWidget: attributes['errorWidget'],
      progressWidget: attributes['progressWidget'],
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key': return parseKey(value);
      case 'name': return value;
      case 'errorWidget': break;
      case 'progressWidget': break;
    }
  }
}