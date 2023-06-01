import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/logging.dart';
import '../utils/utils.dart';
import '../xwidget.dart';


@InflaterDef(inflaterType: "ValueListener", inflatesOwnChildren: true)
class ValueListener extends StatefulWidget {
  final XmlElement element;
  final Dependencies dependencies;
  final String varName;
  final dynamic initialValue;
  final dynamic defaultValue;

  @override
  ValueListenerState createState() => ValueListenerState();

  const ValueListener({
    Key? key,
    required this.element,
    required this.dependencies,
    required this.varName,
    this.initialValue,
    this.defaultValue,
  }) : super(key: key);
}

class ValueListenerState extends State<ValueListener> {
  static const _log = Log("ValueListener");

  late ValueNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _setValueNotifier();
  }

  @override
  void didUpdateWidget(covariant ValueListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setValueNotifier();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _notifier,
      builder: (context, value, _) {
        _log.debug("building with varName=${widget.varName}, initialValue=${widget.initialValue}, defaultValue=${widget.defaultValue}");
        final children = XWidget.inflateXmlElementChildren(widget.element, widget.dependencies);
        return getOnlyChild(widget.element.qualifiedName, children.objects, const SizedBox());
      }
    );
  }

  //===================================
  // Private Methods
  //===================================

  void _setValueNotifier() {
    _notifier = widget.dependencies.listenForChanges(
        widget.varName,
        widget.initialValue,
        widget.defaultValue
    );
  }
}