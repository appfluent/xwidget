import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../xwidget.dart';

typedef XWidgetControllerFactory<T extends Controller> = T Function();

/// A [StatefulWidget] that creates and manages a [Controller] instance.
///
/// [ControllerWidget] is the bridge between XML markup and the
/// [Controller] lifecycle. It is not used directly — the
/// `<Controller>` XML element inflates into this widget via
/// [ControllerWidgetInflater].
///
/// The controller instance is created by [XWidget.createController]
/// using the registered factory for [name].
class ControllerWidget extends StatefulWidget {
  /// The registered name of the controller class to instantiate.
  final String name;

  /// The XML element whose children will be inflated by the controller.
  final XmlElement element;

  /// The dependency scope for data binding and expression evaluation.
  final Dependencies dependencies;

  /// Widget to display if initialization fails. Defaults to
  /// Flutter's [ErrorWidget] if not specified.
  final Widget? errorWidget;

  /// Widget to display while initialization is in progress.
  /// Defaults to [SizedBox.shrink] if not specified.
  final Widget? progressWidget;

  /// Optional key-value pairs passed to the controller, accessible
  /// via [Controller.options].
  final Map<String, dynamic> options;

  /// Whether this controller should request keep-alive behavior from
  /// keep-alive-aware parents such as [PageView].
  final bool keepAlive;

  ControllerWidget({
    super.key,
    required this.name,
    required this.element,
    required this.dependencies,
    this.errorWidget,
    this.progressWidget,
    this.keepAlive = false,
    Map<String, dynamic>? options,
  }) : options = options ?? {};

  @override
  // ignore: no_logic_in_create_state
  Controller createState() => XWidget.createController(name.trim());
}

/// Base class for all controllers.
///
/// Controllers manage business logic and state for XML fragments.
/// They expose data and methods to the fragment via [bindDependencies],
/// which the XML markup accesses through the expression language.
///
/// ## Lifecycle
///
/// 1. **Guard** — [guard] is called to determine whether the
///    controller should proceed. If it returns `false`,
///    [onGuardFailed] provides the rendered widget and
///    initialization is skipped entirely.
/// 2. **Initialization** — [init] is called to perform setup work
///    such as loading data. Can return `void`, a [Future] (which
///    shows [ControllerWidget.progressWidget] while loading), or a [Stream].
/// 3. **Dependency binding** — [bindDependencies] exposes data and
///    methods to the XML fragment.
/// 4. **Child inflation** — XML children are inflated with access
///    to the controller's dependencies.
///
/// ## Guard system
///
/// The [guard] method runs before [init] and determines whether the
/// controller should proceed with initialization and rendering. It
/// can return a [bool] synchronously or a [Future<bool>] for async
/// checks such as authentication.
///
/// When [guard] returns `false`, [init] is skipped and
/// [onGuardFailed] is called to provide the widget to render.
/// When [guard] throws, [DynamicBuilder] displays the
/// [ControllerWidget.errorWidget].
///
/// The default [guard] returns `true`, so existing controllers are
/// unaffected.
abstract class Controller extends State<ControllerWidget>
    with AutomaticKeepAliveClientMixin<ControllerWidget> {
  /// The value returned by the guard/init chain, consumed by
  /// [DynamicBuilder] to manage async state.
  dynamic _initValue;

  /// Whether [guard] returned `true`. Checked in [_inflateChildren]
  /// to decide whether to render children or [onGuardFailed].
  bool _guardPassed = false;

  /// The dependency scope for this controller's fragment.
  @nonVirtual
  Dependencies get dependencies => widget.dependencies;

  /// Optional parameters passed to this controller via the
  /// `options` attribute in XML.
  @nonVirtual
  Map<String, dynamic> get options => widget.options;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  @nonVirtual
  void initState() {
    super.initState();
    _initValue = Future.value(guard()).then((passed) {
      _guardPassed = passed;
      return passed ? init() : null;
    });
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant ControllerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.keepAlive != widget.keepAlive) {
      updateKeepAlive();
    }
  }

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    super.build(context);
    return DynamicBuilder(
      initializer: (_, __) => _initValue,
      builder: (_, deps, __) => _inflateChildren(deps),
      dependencies: widget.dependencies,
      errorWidget: widget.errorWidget,
      progressWidget: widget.progressWidget,
    );
  }

  /// Determines whether the controller should proceed with
  /// initialization and rendering.
  ///
  /// Return `true` to proceed normally, or `false` to skip [init]
  /// and render the widget returned by [onGuardFailed] instead.
  /// Can be synchronous or asynchronous.
  ///
  /// Defaults to `true`. Override to enforce access control,
  /// feature gating, or other preconditions.
  FutureOr<bool> guard() => true;

  /// Called when [guard] returns `false`.
  ///
  /// Override to provide a widget for users who should not see the
  /// controller's content. Return `null` to render a [SizedBox.shrink].
  ///
  /// This is also the appropriate place to schedule side effects
  /// such as navigation redirects via [WidgetsBinding.addPostFrameCallback].
  Widget? onGuardFailed() => null;

  /// Called once after [guard] succeeds to perform setup work.
  ///
  /// Override for data loading, API calls, or other initialization.
  /// Can return `void` for synchronous setup, a [Future] for async
  /// work (which shows [ControllerWidget.progressWidget] while loading), or a
  /// [Stream] for streaming data.
  dynamic init() {}

  /// Called after [init] completes to expose data and methods to
  /// the XML fragment.
  ///
  /// Use [Dependencies.setValue] to make values available to
  /// the expression language in the fragment markup.
  void bindDependencies() {}

  //===================================
  // Private Methods
  //===================================

  /// Builds the controller's content widget.
  ///
  /// If [_guardPassed] is `true`, calls [bindDependencies] and
  /// inflates the XML-defined children. Otherwise, returns the
  /// widget from [onGuardFailed], falling back to [SizedBox.shrink].
  Widget _inflateChildren(Dependencies dependencies) {
    if (_guardPassed) {
      bindDependencies();
      final children = XWidget.inflateXmlElementChildren(
        widget.element,
        dependencies,
        excludeText: true,
        excludeAttributes: true,
      );
      return XWidgetUtils.getOnlyChild("Controller", children.objects, const SizedBox.shrink());
    }
    return onGuardFailed() ?? const SizedBox.shrink();
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
    List<String> text,
  ) {
    return ControllerWidget(
      key: attributes['key'],
      name: attributes['name'],
      element: attributes['_element'],
      dependencies: attributes['_dependencies'],
      errorWidget: attributes['errorWidget'],
      progressWidget: attributes['progressWidget'],
      keepAlive: attributes['keepAlive'] ?? false,
      options: attributes['options'] != null ? {...attributes['options']} : null,
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key':
        return parseKey(value);
      case 'name':
        return value;
      case 'errorWidget':
        break;
      case 'progressWidget':
        break;
      case 'options':
        break;
      case 'keepAlive':
        return parseBool(value);
    }
    return value;
  }
}
