import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/parsers.dart';
import '../utils/utils.dart';
import '../xwidget.dart';
import 'async.dart';

typedef XWidgetControllerFactory<T extends Controller> = T Function();

enum BuildExecution { async, sync }

@InflaterDef(inflaterType: "Controller", inflatesOwnChildren: true)
class ControllerWidget extends StatefulWidget {
  final String name;
  final XmlElement element;
  final Dependencies dependencies;
  final Widget? errorWidget;
  final Widget? progressWidget;
  final BuildExecution build;

  @override
  ControllerWidgetState createState() => ControllerWidgetState();

  const ControllerWidget({
    Key? key,
    required this.name,
    required this.element,
    required this.dependencies,
    this.errorWidget,
    this.progressWidget,
    this.build = BuildExecution.sync,
  }) : super(key: key);
}

class ControllerWidgetState extends State<ControllerWidget> {
  late final dynamic _initValue;
  final List<Controller> _controllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.name.contains(",")) {
      _initStateForMultipleControllers(widget.name.split(","));
    } else {
      _initStateForSingleController(widget.name);
    }
  }

  @override
  void dispose() {
    _disposeOfControllers();
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

  void _initStateForSingleController(String name) {
    final controller = XWidget.createController(name.trim());
    controller._mountedProvider = _getMounted;
    controller._contextProvider = _getContext;
    controller._dependenciesProvider = _getDependencies;
    controller._setStateProvider = setState;
    _controllers.add(controller);
    _initValue = controller.initialize();
  }

  void _initStateForMultipleControllers(List<String> names) {
    final initValues = <dynamic>[];
    final futures = <int>[];
    final streams = <int>[];
    final others = <int>[];

    var index = 0;
    for (final name in names) {
      final controller = XWidget.createController(name.trim());
      controller._mountedProvider = _getMounted;
      controller._contextProvider = _getContext;
      controller._dependenciesProvider = _getDependencies;
      controller._setStateProvider = setState;
      _controllers.add(controller);

      final initValue = controller.initialize();
      if (initValue is Future) {
        futures.add(index);
      } else if (initValue is Stream) {
        streams.add(index);
      } else if (initValue != null) {
        others.add(index);
      }

      initValues.add(initValue);
      index++;
    }

    if (streams.length > 1) {
      throw Exception("Initialization of multiple streams in the same "
          "ControllerWidget not allowed.");
    } else if (streams.isNotEmpty && futures.isNotEmpty) {
      throw Exception("Initialization of streams and futures in the same "
          "ControllerWidget is not allowed");
    } else if (streams.isNotEmpty && others.isNotEmpty) {
      throw Exception("Initialization of streams and other values in the same"
          " ControllerWidget is not allowed");
    } else if (streams.isNotEmpty) {
      _initValue = initValues[streams[0]];
    } else if (futures.isEmpty) {
      _initValue = initValues;
    } else {
      _initValue = Future.wait(initValues.map((value) => (value is Future)
          ? value : Future.value(value)));
    }
  }

  /// Returns the initValue received from [Controller.initialize].
  ///
  /// [Controller.initialize] is called in [setState] instead of being passed
  /// directly to [DynamicBuilder] as the initializer function because we don't
  /// want to reinitialize the controller every time the widget's 'build'
  /// function is called.
  dynamic _initializer(BuildContext context, Dependencies dependencies) {
    return _initValue;
  }

  Widget _builder(BuildContext context, Dependencies dependencies, dynamic initValue) {
    if (_shouldBuild()) {
      if (widget.build == BuildExecution.async) {
        return DynamicBuilder<Widget>(
            initializer: (context, dependencies) async => _inflateChildren(dependencies),
            builder: (context, dependencies, widget) => widget,
            dependencies: dependencies
        );
      }
      return _inflateChildren(dependencies);
    }
    return const SizedBox.shrink();
  }

  Widget _inflateChildren(Dependencies dependencies) {
    _bindDependencies();
    final children = XWidget.inflateXmlElementChildren(widget.element, dependencies, excludeText: true);
    return XWidgetUtils.getOnlyChild("Controller", children.objects, const SizedBox.shrink());
  }

  void _bindDependencies() {
    for (final controller in _controllers) {
      controller.bindDependencies();
    }
  }

  bool _shouldBuild() {
    for (final controller in _controllers) {
      if (!controller.shouldBuild()) return false;
    }
    return true;
  }

  void _disposeOfControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  bool _getMounted() => mounted;

  BuildContext _getContext() => context;

  Dependencies _getDependencies() => widget.dependencies;
}

abstract class Controller {
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
      build: attributes["execution"] ?? BuildExecution.sync,
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key': return parseKey(value);
      case 'name': return value;
      case 'errorWidget': break;
      case 'progressWidget': break;
      case "execution": return parseEnum(BuildExecution.values, value);
    }
    return value;
  }
}
