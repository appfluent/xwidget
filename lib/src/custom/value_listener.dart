import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../xwidget.dart';


class ValueListener extends StatefulWidget {
  final XmlElement element;
  final Dependencies dependencies;
  final String varName;
  final VariableDisposal varDisposal;
  final dynamic initialValue;
  final dynamic defaultValue;

  @override
  ValueListenerState createState() => ValueListenerState();

  const ValueListener({
    super.key,
    required this.element,
    required this.dependencies,
    required this.varName,
    this.varDisposal = VariableDisposal.none,
    this.initialValue,
    this.defaultValue,
  });
}

class ValueListenerState extends State<ValueListener> {
  static const _log = CommonLog("ValueListenerState");

  ValueNotifier? _notifier;
  Key? _notifierOwnerKey;

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
      valueListenable: _notifier!,
      builder: (context, value, _) {
        final children = XWidget.inflateXmlElementChildren(
          widget.element,
          widget.dependencies,
          excludeText: true,
          excludeAttributes: true,
        );
        return XWidgetUtils.getOnlyChild(widget.element.qualifiedName, children.objects, const SizedBox());
      }
    );
  }

  @override
  void dispose() {
    if (_disposeOfNotifier(_notifier)) {
      widget.dependencies.removeValue(widget.varName);
    }
    super.dispose();
  }

  //===================================
  // Private Methods
  //===================================

  void _setValueNotifier() {
    final notifier = widget.dependencies.listenForChanges(
        widget.varName,
        widget.initialValue,
        widget.defaultValue
    );
    if (notifier is ModelValueNotifier) {
      _notifierOwnerKey = notifier.takeOwnership();
    }
    _notifier = notifier;
  }

  bool _disposeOfNotifier(ValueNotifier? notifier) {
    if (notifier != null && widget.varDisposal != VariableDisposal.none) {
      // client requested disposal of variable
      if (notifier is ModelValueNotifier) {
        // notifier is the right class, so we can continue
        if ((widget.varDisposal == VariableDisposal.byOwner && notifier.isOwner(_notifierOwnerKey)) ||
            (widget.varDisposal == VariableDisposal.byLastListener && notifier.hasNoListeners)) {
          // we are the owner or the last listener
          notifier.dispose();
          return true;
        }
      } else {
        // log improper disposal request
        _log.warn("Improper variable disposal request '${widget.varDisposal}' "
            "for varName '${widget.varName}' referencing a notifier of type "
            "'${notifier.runtimeType}'. 'ValueListener' widget only knows how "
            "to dispose of 'DataValueNotifier' instances. Use "
            "'Dependencies.listenForChanges(String) to wrap your data in a "
            "'DataValueNotifier' instance or let 'ValueListener' widget wrap "
            "it automatically.");
      }
    }
    return false;
  }
}

enum VariableDisposal {
  none, byOwner, byLastListener
}

class ValueListenerInflater extends Inflater {
  @override
  String get type => 'ValueListener';

  @override
  bool get inflatesOwnChildren => true;

  @override
  bool get inflatesCustomWidget => true;

  @override
  ValueListener? inflate(
      Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text)
  {
    return ValueListener(
      key: attributes['key'],
      element: attributes['_element'],
      dependencies: attributes['_dependencies'],
      varName: attributes['varName'],
      varDisposal: attributes['varDisposal'] ?? VariableDisposal.none,
      initialValue: attributes['initialValue'],
      defaultValue: attributes['defaultValue'],
    );
  }

  @override
  dynamic parseAttribute(String name, String value) {
    switch (name) {
      case 'key': return parseKey(value);
      case 'varName': return value;
      case 'varDisposal': return parseEnum(VariableDisposal.values, value);
      case 'initialValue': break;
      case 'defaultValue': break;
    }
    return value;
  }
}
