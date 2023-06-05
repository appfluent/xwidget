import 'package:flutter/material.dart' hide Stack;
import 'package:petitparser/context.dart';
import 'package:petitparser/core.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import 'custom/async.dart';
import 'custom/controller.dart';
import 'custom/list_of.dart';
import 'custom/value_listener.dart';
import 'el/parser.dart';
import 'tags/attribute.dart';
import 'tags/builder.dart';
import 'tags/debug.dart';
import 'tags/for_each.dart';
import 'tags/for_loop.dart';
import 'tags/fragment.dart';
import 'tags/handler.dart';
import 'tags/if_else.dart';
import 'tags/variable.dart';
import 'utils/brackets.dart';
import 'utils/logging.dart';
import 'utils/parsers.dart';
import 'utils/resources.dart';


class XWidget {
  static const _log = CommonLog("XWidget");

  static final _controllerInflater = ControllerWidgetInflater();
  static final _dynamicBuilderInflater = DynamicBuilderInflater();
  static final _listOfInflater = ListOfInflater();
  static final _valueListenerInflater = ValueListenerInflater();

  static final _attributeTag = AttributeTag();
  static final _builderTag = BuilderTag();
  static final _dataTag = VariableTag();
  static final _debugTag = DebugTag();
  static final _forEachTag = ForEachTag();
  static final _forLoopTag = ForLoopTag();
  static final _fragmentTag = FragmentTag();
  static final _handlerTag = HandlerTag();
  static final _ifElseTag = IfElseTag();

  static final _inflaters = <String, Inflater>{
    _controllerInflater.type: _controllerInflater,
    _dynamicBuilderInflater.type: _dynamicBuilderInflater,
    _listOfInflater.type: _listOfInflater,
    _valueListenerInflater.type: _valueListenerInflater,
  };

  static final _tags = <String, Tag>{
    _attributeTag.name: _attributeTag,
    _builderTag.name: _builderTag,
    _dataTag.name: _dataTag,
    _debugTag.name: _debugTag,
    _forEachTag.name: _forEachTag,
    _forLoopTag.name: _forLoopTag,
    _fragmentTag.name: _fragmentTag,
    _handlerTag.name: _handlerTag,
    _ifElseTag.name: _ifElseTag,
  };

  static final _icons = <String, IconData>{};
  static final _controllerFactories = <String, XWidgetControllerFactory>{};
  static final _attributeDirective = RegExp(r'^(@[a-z]+/)(.+)$');
  static final _attributeExpression = RegExp(r'^\$\{(.*)\}$');

  //===================================
  // Public Methods
  //===================================

  static void registerIcon(String name, IconData iconData) {
    _icons[name] = iconData;
  }

  static IconData? getIcon(String name) {
    return _icons[name];
  }

  static void registerInflater(Inflater inflater) {
    _inflaters[inflater.type] = inflater;
  }

  static void registerTag(Tag tag) {
    _tags[tag.name] = tag;
  }

  static void registerControllerFactory<T extends Controller>(XWidgetControllerFactory<T> factory) {
    _controllerFactories[T.toString()] = factory;
  }

  static Controller createController(String name) {
    final factory = _controllerFactories[name];
    if (factory == null) throw Exception("XWidget controller factory for '$name' not found");
    return factory();
  }

  static T? inflateFragment<T>(
    String fragmentName,
    Dependencies dependencies, {
    Iterable<XmlAttribute>? inheritedAttributes,
    Map<String, String>? params
  }) {
    // TODO: Allow relative names. The problem lies with builders that inflate fragments, so creating a stack here doesn't work

    final splitIndex = fragmentName.indexOf("?");
    final namePart = splitIndex > -1 ? fragmentName.substring(0, splitIndex).trim() : fragmentName.trim();
    final fragmentFqn = Resources.instance.getFragmentFqn(namePart);
    final fragment = Resources.instance.getFragment(fragmentFqn);

    final queryPart = splitIndex > -1 ? fragmentName.substring(splitIndex + 1).trim() : null;
    final queryParams = queryPart != null && queryPart.isNotEmpty ? Uri.splitQueryString(queryPart) : {};
    queryParams.forEach((key, value) => dependencies[key] = value);

    final results = inflateFromXml(
      xml: fragment,
      dependencies: dependencies,
      inheritedAttributes: inheritedAttributes,
    );
    return results;
  }

  static T? inflateFromXml<T>({
    required String xml,
    required Dependencies dependencies,
    Iterable<XmlAttribute>? inheritedAttributes,

  }) {
    final document = XmlDocument.parse(xml);
    final results = inflateFromXmlElement(
        document.rootElement,
        dependencies,
        inheritedAttributes: inheritedAttributes);
    return results;
  }

  static T? inflateFromXmlElement<T>(
      XmlElement element,
      Dependencies dependencies, {
      Iterable<XmlAttribute>? inheritedAttributes
  }) {
    try {
      final type = element.localName;
      final inflater = _inflaters[type];
      if (inflater == null) throw Exception("XWidget inflater not found for XML element <${element.localName}>");

      final attributes = parseXmlAttributes(
        element,
        dependencies,
        inflater: inflater,
        inheritedAttributes: inheritedAttributes,
      );

      final visible = !attributes.containsKey("visible") || parseBool(attributes["visible"]) == true;
      if (visible) {
        // widget is visible, so let's continue
        if (inflater.inflatesCustomWidget) {
          // inflating a custom widget or object, so include the element and dependencies as 'private' attributes.
          attributes["_element"] = element;
          attributes["_dependencies"] = dependencies;
        }
        if (inflater.inflatesOwnChildren) {
          return inflater.inflate(attributes, [], null);
        } else {
          final children = inflateXmlElementChildren(element, dependencies);
          attributes.addAll(children.attributes);
          return inflater.inflate(attributes, children.objects, children.text.join());
        }
      }
    } catch(e, stacktrace) {
      _log.error("Problem inflating XML element.${dump(element, dependencies)}", e, stacktrace);
    }
    return null;
  }

  static Children inflateXmlElementChildren(
      XmlElement element,
      Dependencies dependencies, {
      Set<String>? excludeElements,
      Set<String>? includeElements,
      bool excludeText = false
  }) {
    final children = Children();
    for (final child in element.children) {
      if ((child is XmlText || child is XmlCDATA) && !excludeText) {
        final text = child.text.trim();
        if (text.isNotEmpty) {
          children.text.add(text);
        }
      } else if (child is XmlElement) {
        // child is an element
        final elementName = child.localName;
        if ((excludeElements == null || !excludeElements.contains(elementName)) &&
            (includeElements == null || includeElements.contains(elementName))) {
          final tag = _tags[elementName];
          if (tag != null) {
            // element is a tag
            final attributes = parseXmlAttributes(child, dependencies);
            final tagChildren = tag.processTag(child, attributes, dependencies);
            children.addAll(tagChildren);
          } else {
            // element is a widget or other object
            final object = inflateFromXmlElement(child, dependencies);
            if (object != null) {
              final attributeName = child.getAttribute("for");
              if (attributeName != null && attributeName.isNotEmpty) {
                children.attributes[attributeName] = object;
              } else {
                children.objects.add(object);
              }
            }
          }
        }
      }
    }
    return children;
  }

  static Map<String, dynamic> parseXmlAttributes(
    XmlElement element,
    Dependencies dependencies, {
    Inflater? inflater,
    Iterable<XmlAttribute>? inheritedAttributes,
  }) {
    final attributes = <String, dynamic>{};
    final mergedAttributes = mergeXmlAttributes(element.attributes, inheritedAttributes);
    for (final attribute in mergedAttributes) {
      try {
        final attributeName = attribute.qualifiedName;
        final attributeValue = parseAttribute(
          attributeName: attributeName,
          attributeValue: attribute.value,
          dependencies: dependencies,
          inflater: inflater,
        );
        attributes[attributeName] = attributeValue;
      } catch (e, stacktrace) {
       _log.error("Problem parsing XML element attribute '${attribute.qualifiedName}'. ${dump(element, dependencies)}", e, stacktrace);
      }
    }
    return attributes;
  }

  static dynamic parseAttribute({
    required String attributeName,
    required String? attributeValue,
    required Dependencies dependencies,
    Inflater? inflater,
  }) {
    if (attributeValue != null && attributeValue.isNotEmpty) {
      final directiveMatch = _attributeDirective.firstMatch(attributeValue);
      if (directiveMatch != null) {
        // the attribute value contains a directive that needs to be resolved
        final directive = directiveMatch.group(1)!;
        final key = directiveMatch.group(2)!;
        switch (directive) {
          case "@fragment/": return inflateFragment(key, dependencies);
          case "@string/": return Resources.instance.getString(key);
          case "@bool/": return Resources.instance.getBool(key);
          case "@int/":  return Resources.instance.getInt(key);
          case "@double/": return Resources.instance.getDouble(key);
          default:
            // validation check failed - unknown directive used
            throw Exception("Unknown attribute directive: '$directive'");
        }
      }
      final expressionMatch = _attributeExpression.firstMatch(attributeValue);
      if (expressionMatch != null) {
        // the attribute value contains an expression that needs to be parsed
        final expression = expressionMatch.group(1);
        if (expression != null && expression.isNotEmpty) {
          final result = parseExpression(dependencies, expression);
          if (result.isSuccess) {
            final value = result.value.evaluate();
            return (inflater != null && value is String) ? inflater.parseAttribute(attributeName, value) : value;
          } else {
            throw Exception("Failed to parse '$expression' of attribute '$attributeName'. ${result.message}");
          }
        }
        return null;
      }
      return inflater?.parseAttribute(attributeName, attributeValue) ?? attributeValue;
    }
    return null;
  }

  static Iterable<XmlAttribute> mergeXmlAttributes(Iterable<XmlAttribute> list1, Iterable<XmlAttribute>? list2) {
    // if list2 is null or empty then just return list1 for efficiency
    if (list2 == null || list2.isEmpty) return list1;

    final attributes = <String, XmlAttribute>{};
    for (final attribute in list1) {
      attributes[attribute.qualifiedName] = attribute;
    }
    for (final attribute in list2) {
      attributes[attribute.qualifiedName] = attribute;
    }
    return attributes.values;
  }

  static dump(XmlElement element, Dependencies dependencies) {
    return "\n------- XML Element --------\n${element.toXmlString(pretty: true)}"
           "\n------- Dependencies -------\n$dependencies";
  }

  static Result parseExpression(Dependencies dependencies, String expression) {
    try {
      final parser = dependencies.getExpressionParser();
      dependencies["_dependencies"] = dependencies;
      return parser.parse(expression);
    } finally {
      dependencies.remove("_dependencies");
    }
  }

  static String parseDocument(String input, Dependencies dependencies) {
    final parser = dependencies.getExpressionParser();
    final regExp = RegExp(r"\$\{(.*?)\}");
    return input.replaceFirstMapped(regExp, (match) {
      final result = parser.parse(match.group(1) ?? "");
      if (result.isSuccess) {
        return result.value.evaluate() ?? "";
      }
      throw Exception("Failed to parse '${match.group(0)}' in document '$input'. ${result.message}");
    });
  }
}

//===================================
// Support Classes
//===================================

class Children {
  final text = <String>[];
  final objects = <dynamic>[];
  final attributes = <String, dynamic>{};

  addAll(Children? children) {
    if (children != null) {
      text.addAll(children.text);
      objects.addAll(children.objects);
      attributes.addAll(children.attributes);
    }
  }

  getWidgets() {
    final widgets = <Widget>[];
    for (var obj in objects) {
      if (obj is Widget) widgets.add(obj);
    }
    return widgets;
  }
}

// class InflaterInfo {
//   final String type;
//
//   const InflaterInfo({required this.type});
// }

class InflaterDef {
  final String? inflaterType;

  final bool inflatesOwnChildren;

  const InflaterDef({this.inflaterType, required this.inflatesOwnChildren});
}

class Dependencies {
  static const _expressionParser = "_expressionParser";
  static final _globalData = <String, dynamic>{};
  static const _uuid = Uuid();

  final id = _uuid.v4();
  final _data = <String, dynamic>{};

  Dependencies([Map<String, dynamic>? data]) {
    if (data != null) _data.addAll(data);
  }

  void addAll(Map<String, dynamic> data) {
    _data.addAll(data);
  }

  dynamic operator [](String key) {
    final resolved = _resolvePath(key);
    return resolved.value[resolved.key];
  }

  void operator []=(String key, dynamic value) {
    final resolved = _resolvePath(key);
    resolved.value[resolved.key] = value;
  }

  void setValue(String path, dynamic value) {
    final resolved = _resolvePath(path);
    resolved.value.setValue(resolved.key, value);
  }

  dynamic getValue(String path) {
    final resolved = _resolvePath(path);
    return resolved.value.getValue(resolved.key);
  }

  dynamic remove(String key) {
    final resolved = _resolvePath(key);
    return resolved.value.remove(resolved.key);
  }

  ValueNotifier listenForChanges(String path, dynamic initialValue, dynamic defaultValue) {
    final resolved = _resolvePath(path);
    return resolved.value.listenForChanges(path, initialValue, defaultValue);
  }

  void putIfAbsent(String key, dynamic value) {
    final resolved = _resolvePath(key);
    if (!resolved.value.containsKey(resolved.key)) {
      resolved.value[resolved.key] = value;
    }
  }

  Parser getExpressionParser() {
    var parser = _data[_expressionParser];
    if (parser == null) {
      final definition = ELParserDefinition(data: _data);
      parser = definition.build(start: definition.expression);
      _data[_expressionParser] = parser;
    }
    return parser as Parser;
  }

  // TODO: figure out a way to automatically dispose of copies
  Dependencies copy({Map<String, dynamic>? addData, List<String>? preserveData}) {
    final copy = Dependencies(_data);
    copy._data.remove(_expressionParser);
    if (addData != null) {
      copy._data.addAll(addData);
      if (preserveData != null) {
        for (final key in preserveData) {
          copy._data[key] = _data[key];
        }
      }
    }
    return copy;
  }

  @override
  String toString() {
    return "id: $id, data:\n $_data";
  }

  MapEntry<String, Map<String, dynamic>> _resolvePath(String key) {
    return key.startsWith("global.") ? MapEntry(key.substring(7), _globalData) : MapEntry(key, _data);
  }
}

//===================================
// Abstract Classes
//===================================

abstract class Inflater<T> {
  /// the inflater identifier (tag name)
  String get type;

  // if true, the widget is responsible for calling XWidget.inflateXmlElementChildren to build its children
  bool get inflatesOwnChildren;

  // if true, special private objects are added to the attributes passed to the inflate method
  bool get inflatesCustomWidget;

  /// inflate the xml element into a flutter object.
  T? inflate(Map<String, dynamic> attributes, List<dynamic> children, String? text);

  dynamic parseAttribute(String name, String value);
}

abstract class Tag {
  /// the tag identifier
  String get name;

  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies);
}
