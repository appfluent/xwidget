import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../xwidget.dart';


class EventListener extends StatefulWidget {
  final XmlElement element;
  final Dependencies dependencies;
  final Enum event;
  final EventListenerCallback? onEvent;

  @override
  EventListenerState createState() => EventListenerState();

  const EventListener({
    super.key,
    required this.element,
    required this.dependencies,
    required this.event,
    this.onEvent,
  });
}

class EventListenerState extends State<EventListener> with EventNotifier {

  @override
  void initState() {
    super.initState();
    addListener(widget.event, _handleEvent);
  }

  @override
  Widget build(BuildContext context) {
      final children = XWidget.inflateXmlElementChildren(
        widget.element,
        widget.dependencies,
        excludeText: true,
        excludeAttributes: true,
      );
      return XWidgetUtils.getOnlyChild(
          widget.element.qualifiedName,
          children.objects,
          const SizedBox()
      );
  }

  @override
  void dispose() {
    removeListener(widget.event, _handleEvent);
    super.dispose();
  }

  _handleEvent(Enum event, dynamic payload) {
    if (widget.onEvent != null) {
      widget.onEvent!(event, payload);
    }
    setState(() { });
  }
}

class EventListenerInflater extends Inflater {
  @override
  String get type => 'EventListener';

  @override
  bool get inflatesOwnChildren => true;

  @override
  bool get inflatesCustomWidget => true;

  @override
  EventListener inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text
  ) {
    return EventListener(
      key: attributes['key'],
      element: attributes['_element'],
      dependencies: attributes['_dependencies'],
      event: attributes['event'],
      onEvent: attributes['onEvent'],
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key': return parseKey(value);
      case 'event': return parseEvent(value);
      case 'onEvent': break;
    }
    return value;
  }
}