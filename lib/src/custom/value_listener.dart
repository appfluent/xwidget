import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../utils/parsers.dart';
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
        final children = XWidget.inflateXmlElementChildren(widget.element, widget.dependencies);
        return XWidgetUtils.getOnlyChild(widget.element.qualifiedName, children.objects, const SizedBox());
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

class ValueListenerInflater extends Inflater {

  @override
  String get type => 'ValueListener';

  @override
  bool get inflatesOwnChildren => true;

  @override
  bool get inflatesCustomWidget => true;

  @override
  ValueListener? inflate(Map<String, dynamic> attributes, List<dynamic> children, List<String> text) {
    return ValueListener(
      key: attributes['key'],
      element: attributes['_element'],
      dependencies: attributes['_dependencies'],
      varName: attributes['varName'],
      initialValue: attributes['initialValue'],
      defaultValue: attributes['defaultValue'],
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key': return parseKey(value);
      case 'varName': return value;
      case 'initialValue': break;
      case 'defaultValue': break;
    }
  }
}