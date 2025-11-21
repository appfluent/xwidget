import 'package:flutter/material.dart';

import '../../xwidget.dart';


typedef InitializerFunction = dynamic Function(
    BuildContext context,
    Dependencies dependencies
);

typedef BuilderFunction<T> = Widget Function(
    BuildContext context,
    Dependencies dependencies,
    T initValue
);

class DynamicBuilder<T> extends StatefulWidget {
  final InitializerFunction? initializer;
  final BuilderFunction<T> builder;
  final dynamic initValue;
  final Widget? errorWidget;
  final Widget? progressWidget;
  final Dependencies dependencies;

  DynamicBuilder({
    super.key,
    required this.builder,
    required this.dependencies,
    this.errorWidget,
    this.progressWidget,
    this.initializer,
    this.initValue,
  }) {
    if (initializer != null && initValue != null) {
      throw Exception("XWidget DynamicBuilder can't have an [initializer] "
          "function and an [initValue]. You may return an initial value from "
          "[initializer] or pass it directly in [initValue], but not both.");
    }
  }

  @override
  DynamicBuilderState<T> createState() => DynamicBuilderState<T>();
}

class DynamicBuilderState<T> extends State<DynamicBuilder<T>> {
  static const _log = CommonLog("DynamicBuilderState");

  late final dynamic _initValue;

  @override
  void initState() {
    super.initState();
    final initializer = widget.initializer;
    _initValue = initializer != null
        ? initializer(context, widget.dependencies)
        : widget.initValue;
  }

  @override
  Widget build(BuildContext context) {
    if (_initValue is Future) {
      return FutureBuilder(
        future: _initValue,
        builder: _asyncBuilder,
      );
    } else if (_initValue is Stream) {
      return StreamBuilder(stream: _initValue, builder: _asyncBuilder);
    } else {
      return widget.builder(context, widget.dependencies, _initValue);
    }
  }

  //===================================
  // Private Methods
  //===================================

  Widget _asyncBuilder(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasError) {
      _log.error(
          "Problem initializing DynamicBuilderState",
          snapshot.error,
          snapshot.stackTrace
      );
      return widget.errorWidget ?? ErrorWidget(snapshot.error!);
    } else if (snapshot.connectionState == ConnectionState.done ||
               snapshot.connectionState == ConnectionState.active) {
      try {
        return widget.builder(context, widget.dependencies, snapshot.data);
      } catch (error) {
        return widget.errorWidget ?? _defaultErrorWidget(error);
      }
    } else {
      return widget.progressWidget ?? _defaultProgressWidget();
    }
  }

  Widget _defaultErrorWidget(dynamic e) {
    return Center(
      child: ErrorWidget(e),
    );
  }

  Widget _defaultProgressWidget() {
    return const SizedBox.shrink();
  }
}

class DynamicBuilderInflater extends Inflater {
  @override
  String get type => 'DynamicBuilder';

  @override
  bool get inflatesOwnChildren => false;

  @override
  bool get inflatesCustomWidget => true;

  @override
  DynamicBuilder? inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text
  ) {
    return DynamicBuilder(
      key: attributes['key'],
      builder: attributes['builder'],
      dependencies: attributes['_dependencies'],
      errorWidget: attributes['errorWidget'],
      progressWidget: attributes['progressWidget'],
      initializer: attributes['initializer'],
      initValue: attributes['initValue'],
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key': return parseKey(value);
      case 'builder': break;
      case 'errorWidget': break;
      case 'progressWidget': break;
      case 'initializer': break;
      case 'initValue': break;
      case 'disposeOfDependencies': return parseBool(value);
    }
    return value;
  }
}
