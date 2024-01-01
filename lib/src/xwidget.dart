import 'dart:convert';

import 'package:flutter/material.dart' hide Stack;
import 'package:petitparser/core.dart';
import 'package:xml/xml.dart';

import 'custom/async.dart';
import 'custom/collection.dart';
import 'custom/controller.dart';
import 'custom/value_listener.dart';
import 'el/parser.dart';
import 'tags/builder.dart';
import 'tags/debug.dart';
import 'tags/for_each.dart';
import 'tags/for_loop.dart';
import 'tags/fragment.dart';
import 'tags/callback.dart';
import 'tags/if_else.dart';
import 'tags/variable.dart';
import 'utils/brackets.dart';
import 'utils/logging.dart';
import 'utils/parsers.dart';
import 'utils/resources.dart';
import 'utils/utils.dart';

class XWidget {
  static const _log = CommonLog("XWidget");

  static final _controllerInflater = ControllerWidgetInflater();
  static final _dynamicBuilderInflater = DynamicBuilderInflater();
  static final _listInflater = ListInflater();
  static final _mapInflater = MapInflater();
  static final _mapEntryInflater = MapEntryInflater();
  static final _paramInflater = ParamInflater();
  static final _valueListenerInflater = ValueListenerInflater();

  static final _builderTag = BuilderTag();
  static final _callbackTag = CallbackTag();
  static final _debugTag = DebugTag();
  static final _forEachTag = ForEachTag();
  static final _forLoopTag = ForLoopTag();
  static final _fragmentTag = FragmentTag();
  static final _ifElseTag = IfElseTag();
  static final _variableTag = VariableTag();

  static final _inflaters = <String, Inflater>{
    _controllerInflater.type: _controllerInflater,
    _dynamicBuilderInflater.type: _dynamicBuilderInflater,
    _listInflater.type: _listInflater,
    _mapInflater.type: _mapInflater,
    _mapEntryInflater.type: _mapEntryInflater,
    _paramInflater.type: _paramInflater,
    _valueListenerInflater.type: _valueListenerInflater,
  };

  static final _tags = <String, Tag>{
    _builderTag.name: _builderTag,
    _callbackTag.name: _callbackTag,
    _debugTag.name: _debugTag,
    _forEachTag.name: _forEachTag,
    _forLoopTag.name: _forLoopTag,
    _fragmentTag.name: _fragmentTag,
    _ifElseTag.name: _ifElseTag,
    _variableTag.name: _variableTag,
  };

  static final _icons = <String, IconData>{};
  static final _controllerFactories = <String, XWidgetControllerFactory>{};
  static final _attributeContainsExpressions = RegExp(r"\$\{(.*?)}");
  static final _xmlCache = <String, XmlDocument>{};

  /// Enable or disable fragment XML caching
  ///
  /// If enabled, the fragment's parsed XML is cached until the cache is
  /// cleared.
  /// DEFAULT: false
  static bool xmlCacheEnabled = true;

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
    registerControllerFactoryForName(T.toString(), factory);
  }

  static void registerControllerFactoryForName(String name, XWidgetControllerFactory factory) {
    _controllerFactories[name] = factory;
  }

  static Controller createController(String name) {
    final factory = _controllerFactories[name];
    if (factory != null) return factory();
    throw Exception("XWidget controller factory for '$name' not found");
  }

  /// Clear fragment XML cache
  static void clearXmlCache() {
    _xmlCache.clear();
  }

  static T? inflateFragment<T>(
    String fragmentName,
    Dependencies dependencies, {
    Iterable<XmlAttribute>? inheritedAttributes,
    Map<String, dynamic>? params
  }) {
    String name;
    final splitIndex = fragmentName.indexOf("?");
    if (splitIndex > -1) {
      // process params in name
      name = fragmentName.substring(0, splitIndex).trim();
      final query = fragmentName.substring(splitIndex + 1).trim();
      final queryParams = query.isNotEmpty ? Uri.splitQueryString(query) : {};
      queryParams.forEach((key, value) => dependencies.setValue(key, value));
    } else {
      name = fragmentName.trim();
    }
    if (params != null && params.isNotEmpty) {
      // process formal params
      params.forEach((key, value) => dependencies.setValue(key, value));
    }
    return inflateFromXmlElement(
      getFragmentXml(name).rootElement,
      dependencies,
      inheritedAttributes: inheritedAttributes,
    );
  }

  static T? inflateFromXmlElement<T>(
    XmlElement element,
    Dependencies dependencies, {
    Iterable<XmlAttribute>? inheritedAttributes
  }) {
    try {
      final type = element.localName;
      final inflater = _inflaters[type];
      if (inflater == null) {
        throw Exception("XWidget inflater not found for XML element <${element.localName}>");
      }

      final attributes = parseXmlAttributes(
        element,
        dependencies,
        inflater: inflater,
        inheritedAttributes: inheritedAttributes,
      );

      if (!attributes.containsKey("visible") || parseBool(attributes["visible"]) == true) {
        // widget is visible, so let's continue
        if (inflater.inflatesCustomWidget) {
          // inflating a custom widget or object, so include the element and
          // dependencies as 'private' attributes.
          attributes["_element"] = element;
          attributes["_dependencies"] = dependencies;
        }
        if (inflater.inflatesOwnChildren) {
          return inflater.inflate(attributes, [], []);
        } else {
          final children = inflateXmlElementChildren(element, dependencies);
          attributes.addAll(children.attributes);
          return inflater.inflate(attributes, children.objects, children.text);
        }
      }
    } catch (e, stacktrace) {
      _log.error("Problem inflating XML element.${dump(element, dependencies)}", e, stacktrace);
    }
    return null;
  }

  static Children inflateXmlElementChildren(
      XmlElement element,
      Dependencies dependencies, {
      Set<String>? excludeElements,
      bool excludeText = false
  }) {
    final children = Children();
    for (final child in element.children) {
      if (!excludeText && (child is XmlText || child is XmlCDATA)) {
        if (child.value != null && child.value!.isNotEmpty) {
          children.text.add(child.value!);
        }
      } else if (child is XmlElement) {
        // child is an element
        final elementName = child.localName;
        if (excludeElements == null || excludeElements.isEmpty || !excludeElements.contains(elementName)) {
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
    // IMPORTANT: startsWith and endsWith are much faster than RegExp with
    // numerous iterations. Since parsing is called 1000s of times, it needs
    // to be as efficient as possible.

    if (attributeValue == null || attributeValue.isEmpty) return null;
    if (attributeValue.startsWith("\${") && attributeValue.endsWith("}")) {
      // the attribute value is an expression that needs to be parsed
      final value = parseExpression(attributeValue.substring(2, attributeValue.length - 1), dependencies);
      return (inflater != null && value is String)
          ? inflater.parseAttribute(attributeName, value)
          : value;
    }
    if (attributeValue.startsWith("@")) {
      // possible directive
      if (attributeValue.startsWith("@string/")) {
        return Resources.instance.getString(attributeValue.substring(8, attributeValue.length));
      }
      if (attributeValue.startsWith("@bool/")) {
        return Resources.instance.getBool(attributeValue.substring(6, attributeValue.length));
      }
      if (attributeValue.startsWith("@int/")) {
        return Resources.instance.getInt(attributeValue.substring(5, attributeValue.length));
      }
      if (attributeValue.startsWith("@double/")) {
        return Resources.instance.getDouble(attributeValue.substring(8, attributeValue.length));
      }
    }

    final value = parseAllExpressions(attributeValue, dependencies);
    return (inflater != null)
        ? inflater.parseAttribute(attributeName, value)
        : value;
  }

  static Iterable<XmlAttribute> mergeXmlAttributes(
      Iterable<XmlAttribute> list1,
      Iterable<XmlAttribute>? list2
  ) {
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

  static String parseAllExpressions(String input, Dependencies dependencies) {
    // for performance reasons, check input for possible expressions before
    // using a regexp
    if (input.contains("\${")) {
      // possible embedded expression
      return input.replaceAllMapped(_attributeContainsExpressions, (Match match) {
        // parse embedded expression
        final value = parseExpression(match[1]!, dependencies);
        return value != null ? value.toString() : "";
      });
    }
    return input;
  }

  static dynamic parseExpression(String expression, Dependencies dependencies) {
    if (expression.isEmpty) return expression;

    final parser = dependencies.getExpressionParser();
    final result = parser.parse(expression);
    if (result is Success) return result.value.evaluate();

    throw Exception("Failed to parse EL expression '$expression'. ${result.message}");
  }

  static XmlDocument getFragmentXml(String name) {
    XmlDocument? xmlDocument;
    if (xmlCacheEnabled) {
      xmlDocument = _xmlCache[name];
    }
    if (xmlDocument == null) {
      final fragmentFqn = Resources.instance.getFragmentFqn(name);
      final xmlString = Resources.instance.getFragment(fragmentFqn);
      xmlDocument = XmlDocument.parse(xmlString);
      if (xmlCacheEnabled) {
        _xmlCache[name] = xmlDocument;
      }
    }
    return xmlDocument;
  }

  static Dependencies scopeDependencies(
      XmlElement element,
      Dependencies dependencies,
      String? scope,
      [String defaultScope = "inherit"]
  ) {
    if (CommonUtils.isBlank(scope)) {
      scope = defaultScope;
      for (final child in element.children) {
        if (child is XmlElement && child.localName == "var") {
          scope = "copy";
        }
      }
    }
    switch (scope) {
      case "new": return Dependencies();
      case "copy": return dependencies.copy();
      case "inherit": return dependencies;
      default: throw Exception("Invalid Dependencies scope '$scope'");
    }
  }

  static dump(XmlElement element, Dependencies dependencies) {
    return "\n------- XML Element --------\n${element.toXmlString(pretty: true)}"
        "\n------- Dependencies -------\n$dependencies";
  }
}

//===================================
// Support Classes
//===================================

class Children {
  /// Holds all parsed lines of text
  final text = <String>[];

  /// Holds all inflated classes.
  final objects = <dynamic>[];

  /// Holds all parsed attributes
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

/// A class annotation for custom widget inflaters.
///
/// Use this class annotation to configure inflaters for custom widgets and
/// helpers.
/// ```dart
/// @InflaterDef(inflaterType: 'MyTitle', inflatesOwnChildren: true)
/// class MyTitleWidget {
/// ...
/// }
/// ```
/// Create a null `const` variable in your inflater spec Dart file.
/// ```dart
/// const MyTitleWidget? _myTitleWidget = null;
/// ```
class InflaterDef {
  /// The XML element name for the inflater.
  ///
  /// When 'null', XWidget will use the class name as the default.
  final String? inflaterType;

  /// Whether the class is responsible for calling
  /// XWidget.inflateXmlElementChildren to build its children.
  final bool inflatesOwnChildren;

  const InflaterDef({this.inflaterType, required this.inflatesOwnChildren});
}

class Dependencies {
  static const _expressionParser = "_expressionParser";
  static final _globalData = <String, dynamic>{};

  final _data = <String, dynamic>{};

  Dependencies([Map<String, dynamic>? data]) {
    if (data != null) addAll(data);
  }

  /// Adds all key/value dependency pairs of [data] to this instance.
  ///
  /// Supports dot/bracket notation and global references in keys.
  Dependencies addAll(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      setValue(entry.key, entry.value);
    }
    return this;
  }

  /// Returns the dependency references by [key] or null.
  ///
  /// Supports global references, but does not support dot/bracket notation in
  /// keys.
  dynamic operator [](String key) {
    final resolved = _getDataStore(key);
    return resolved.value[resolved.key];
  }

  /// Adds or replaces a dependency referenced by [key].
  ///
  /// Supports global references, but does not support dot/bracket notation in
  /// keys.
  void operator []=(String key, dynamic value) {
    final resolved = _getDataStore(key);
    resolved.value[resolved.key] = value;
  }

  /// Adds or replaces a dependency referenced by [path].
  ///
  /// Supports dot/bracket notation and global references.
  /// For example, `dependencies.setValue('user.email[0]', 'name@example.com');`
  void setValue(String path, dynamic value) {
    final resolved = _getDataStore(path);
    resolved.value.setValue(resolved.key, value);
  }

  /// Returns the dependency referenced by [path] or null.
  ///
  /// Supports dot/bracket notation and global references in keys.
  /// For example, `dependencies.getValue('user.email[0]');`
  dynamic getValue(String path) {
    final resolved = _getDataStore(path);
    return resolved.value.getValue(resolved.key);
  }

  /// Removes the dependency referenced by [key].
  ///
  /// Returns the removed dependency or null.
  ///
  /// Supports dot/bracket notation and global references in keys.
  /// Returns the removed value.
  dynamic removeValue(String key) {
    final resolved = _getDataStore(key);
    return resolved.value.removeValue(resolved.key);
  }

  /// Creates or returns the existing [ValueNotifier] for the dependency
  /// referenced by [path].
  ///
  /// Sets the notifier's value to [initialValue], if provided, otherwise it's
  /// set to the existing dependency value. If both are null, then the
  /// notifier's value is set to [defaultValue].
  ValueNotifier listenForChanges(String path, dynamic initialValue, dynamic defaultValue) {
    final resolved = _getDataStore(path);
    return resolved.value.listenForChanges(resolved.key, initialValue, defaultValue);
  }

  /// Adds the [value] as a dependency for the specified [key] if it doesn't
  /// already exist.
  void putIfAbsent(String key, dynamic value) {
    final resolved = _getDataStore(key);
    if (!resolved.value.containsKey(resolved.key)) {
      resolved.value[resolved.key] = value;
    }
  }

  /// Gets the expression parser bound to this instance, or creates and binds a
  /// new one if one doesn't exist.
  Parser getExpressionParser() {
    var parser = _data[_expressionParser];
    if (parser == null) {
      final definition = ELParserDefinition(data: _data, globalData: _globalData);
      parser = definition.build();
      _data[_expressionParser] = parser;
    }
    return parser as Parser;
  }

  /// Creates a shallow copy.
  ///
  /// The copy excludes the expression parser, if there is one, because the
  /// parser can only be bound to one [Dependencies] instance. A new parser is
  /// created and bound to the copy when needed.
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

  /// Returns a formatted JSON string representation of this instance.
  @override
  String toString() {
    return JsonEncoder.withIndent('  ', (value) => value?.toString()).convert({
      "data": _data,
      "global": _globalData
    });
  }

  /// Gets local or global data depending on the key's prefix
  MapEntry<String, Map<String, dynamic>> _getDataStore(String key) {
    if (key == "global") return MapEntry("", _globalData);
    if (key.startsWith("global.")) return MapEntry(key.substring(7), _globalData);
    return MapEntry(key, _data);
  }
}

//===================================
// Abstract Classes
//===================================

/// The base class for all inflaters.
///
/// While it's possible to manually create an inflater by implementing this
/// class, the best practice is to use the @InflaterDef annotation on your
/// class and let XWidget generate the inflater by running
/// `dart run xwidget:generate`.
abstract class Inflater<T> {
  /// The XML element name for the inflater.
  String get type;

  /// Whether the class is responsible for calling
  /// XWidget.inflateXmlElementChildren to build its children.
  bool get inflatesOwnChildren;

  /// Whether special private objects are added to the attribute map passed to
  /// the inflate method
  ///
  /// An object is considered 'private' if its key begins with an
  /// underscore (_). Schema attributes are not
  /// generated for these keys.
  ///
  /// There are two:
  /// - _element
  /// - _dependencies
  bool get inflatesCustomWidget;

  /// Inflates an xml element into a flutter object.
  T? inflate(Map<String, dynamic> attributes,
      List<dynamic> children,
      List<String> text
  );

  /// Parses an XML attribute into a constructor argument
  dynamic parseAttribute(String name, String value);
}

/// The base class for all tags.
///
/// All tags must implement this class and then register themselves using
/// `XWidget.registerTag(...);
abstract class Tag {
  /// The XML element name for the tag.
  String get name;

  /// Executes the tag's implementation.
  ///
  /// If the tag creates any children, they are return in a [Children] instance.
  Children? processTag(
      XmlElement element,
      Map<String, dynamic> attributes,
      Dependencies dependencies
  );
}
