import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Stack;
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';
import 'package:xwidget_el/xwidget_el.dart';

import 'analytics/analytics.dart';
import 'custom/async.dart';
import 'custom/collection.dart';
import 'custom/controller.dart';
import 'custom/event_listener.dart';
import 'custom/media.dart';
import 'custom/value_listener.dart';
import 'tags/builder.dart';
import 'tags/callback.dart';
import 'tags/debug.dart';
import 'tags/for_each.dart';
import 'tags/for_loop.dart';
import 'tags/fragment.dart';
import 'tags/if_else.dart';
import 'tags/variable.dart';
import 'utils/logging/log_handler.dart';
import 'utils/platform/platform_utils.dart';
import 'utils/resources.dart';
import 'utils/xml.dart';

class XWidget {
  static final _log = Logger("XWidget");

  static final _controllerInflater = ControllerWidgetInflater();
  static final _dynamicBuilderInflater = DynamicBuilderInflater();
  static final _eventListenerInflater = EventListenerInflater();
  static final _itemInflater = ItemInflater();
  static final _listInflater = ListInflater();
  static final _mapInflater = MapInflater();
  static final _mapEntryInflater = MapEntryInflater();
  static final _mediaQueryInflater = MediaQueryWidgetInflater();
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
    _eventListenerInflater.type: _eventListenerInflater,
    _itemInflater.type: _itemInflater,
    _listInflater.type: _listInflater,
    _mapInflater.type: _mapInflater,
    _mapEntryInflater.type: _mapEntryInflater,
    _mediaQueryInflater.type: _mediaQueryInflater,
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
  static final _fragmentStack = <Fragment>[];
  static bool _wasFragmentErrorTracked = false;

  /// Enable or disable fragment XML caching
  ///
  /// If enabled, the fragment's parsed XML is cached until the cache is
  /// cleared.
  /// DEFAULT: false
  static bool xmlCacheEnabled = true;

  // EL parser
  static final elParser = ELParser();

  //===================================
  // Public Methods
  //===================================

  /// Initializes the XWidget framework.
  ///
  /// This method must be called before using any XWidget features, typically
  /// in the app's `main()` function before `runApp()`. It configures logging,
  /// requests persistent storage, and loads all fragment and value resources
  /// needed for server-driven UI rendering.
  ///
  /// Resources can be loaded from local assets, XWidget Cloud, or both.
  /// When using XWidget Cloud, [projectKey] is required for all cloud
  /// services, and [storageKey] is required for downloading resources.
  ///
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await XWidget.initialize(
  ///     fragmentsPath: 'assets/fragments',
  ///     valuesPath: 'assets/values',
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// - [fragmentsPath]: Asset path to local XML fragment resources.
  /// - [valuesPath]: Asset path to local value resources.
  /// - [projectKey]: XWidget Cloud project key. Required for all cloud
  ///   services including analytics and resource delivery.
  /// - [storageKey]: XWidget Cloud storage key. Required for downloading
  ///   cloud-hosted resources.
  /// - [channel]: The cloud channel to download resources from (e.g.
  ///   `'stable'`, `'beta'`).
  /// - [version]: The specific resource version to download or the version of
  ///   the local resource
  /// - [logLevel]: Minimum log level for XWidget's internal logging.
  ///   Defaults to [Level.INFO].
  static Future<void> initialize({
    String? fragmentsPath, // path to fragment resources
    String? valuesPath, // path to value resources
    String? projectKey, // cloud project key - required for all cloud services
    String? storageKey, // cloud storage key - require for download services
    String? channel, // cloud channel to download resources from
    String? version,
    Duration? downloadTimeout,
    AssetBundle? assetBundle,
    Level logLevel = Level.INFO,
  }) async {
    Logger.root.level = logLevel;
    Logger.root.onRecord.listen(defaultLogHandler);
    await requestStoragePersistence();
    await Resources.instance.loadResources(
      fragmentsPath: fragmentsPath,
      valuesPath: valuesPath,
      projectKey: projectKey,
      storageKey: storageKey,
      channel: channel,
      version: version,
      downloadTimeout: downloadTimeout,
      assetBundle: assetBundle,
    );
  }

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

  static void registerModel<T extends Model>(
    ModelFactory<T> factory, [
    List<PropertyTransformer>? transformers,
  ]) {
    Models.register<T>(factory, transformers);
  }

  static void registerTypeConverter<T>(TypeConverter<T> function) {
    TypeConverters.register<T>(function);
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

  /// Pushes a new route onto the navigator by inflating an XML fragment.
  ///
  /// This is a convenience method for navigating to a fragment-backed page.
  /// It inflates the fragment specified by [fragmentName] into a widget and
  /// pushes it onto the navigation stack using either a [MaterialPageRoute]
  /// or [CupertinoPageRoute].
  ///
  /// The route name defaults to [fragmentName] unless [pageName] is
  /// provided, which is useful for analytics tracking and route-aware
  /// widgets like [NavigationObserver].
  ///
  /// Example:
  /// ```dart
  /// XWidget.pushFragment(
  ///   context,
  ///   'screens/settings',
  ///   dependencies,
  ///   pageName: '/settings',
  ///   params: {'userId': currentUser.id},
  /// );
  /// ```
  ///
  /// - [context]: The build context used to locate the [Navigator].
  /// - [fragmentName]: The name of the fragment resource to inflate.
  /// - [dependencies]: The dependency scope for data binding and
  ///   expression evaluation within the fragment.
  /// - [pageName]: Optional route name for the [RouteSettings]. Defaults
  ///   to [fragmentName] if omitted.
  /// - [params]: Optional key-value pairs passed to the fragment during
  ///   inflation. See [inflateFragment] for details on parameter handling.
  /// - [cupertinoStyle]: If `true`, uses [CupertinoPageRoute] for an
  ///   iOS-style page transition. Defaults to `false`, which uses
  ///   [MaterialPageRoute].
  static void pushFragment(
    BuildContext context,
    String fragmentName,
    Dependencies dependencies, {
    String? pageName,
    Map<String, dynamic>? params,
    bool cupertinoStyle = false,
  }) {
    final settings = RouteSettings(name: pageName ?? fragmentName);
    builder(_) => XWidget.inflateFragment(fragmentName, dependencies, params: params) as Widget;

    final route = (cupertinoStyle)
        ? CupertinoPageRoute(settings: settings, builder: builder)
        : MaterialPageRoute(settings: settings, builder: builder);

    Navigator.of(context).push(route);
  }

  /// Inflates an XML fragment by name and returns the resulting widget tree.
  ///
  /// This is the primary method for rendering dynamic UIs from XML
  /// fragment resources. It resolves the fragment by [fragmentName], injects
  /// any query parameters and additional [params] into the [dependencies]
  /// scope, and inflates the fragment's XML into a widget tree of type [T].
  ///
  /// A render event is tracked on success. On error, a tracking record is
  /// logged only at the top of the fragment stack to avoid duplicate error
  /// entries as exceptions bubble up through nested fragments.
  ///
  /// Returns `null` if the inflated output is null.
  ///
  /// Example:
  /// ```dart
  /// final widget = XWidget.inflateFragment<Widget>(
  ///   'screens/home',
  ///   dependencies,
  ///   params: {'title': 'Welcome'},
  /// );
  /// ```
  ///
  /// - [fragmentName]: The name of the fragment resource to inflate.
  /// - [dependencies]: The dependency scope used for data binding and
  ///   expression evaluation within the fragment.
  /// - [inheritedAttributes]: Optional XML attributes inherited from a
  ///   parent fragment or element, typically used for attribute propagation
  ///   across fragment boundaries.
  /// - [params]: Optional key-value pairs injected into [dependencies]
  ///   before inflation. These override any query parameters defined on
  ///   the fragment itself.
  ///
  /// Throws if the fragment cannot be found or if inflation fails.
  static T? inflateFragment<T>(
    String fragmentName,
    Dependencies dependencies, {
    Iterable<XmlAttribute>? inheritedAttributes,
    Map<String, dynamic>? params,
  }) {
    _fragmentStack.add(FragmentPlaceholder(requestedName: fragmentName));

    try {
      final fragment = getFragment(fragmentName);
      _fragmentStack[_fragmentStack.length - 1] = fragment;

      // add params to dependencies
      fragment.queryParams.forEach((key, val) => dependencies.setValue(key, val));
      if (params != null && params.isNotEmpty) {
        params.forEach((key, value) => dependencies.setValue(key, value));
      }

      final output = inflateFromXmlElement(
        fragment.xmlDocument.rootElement,
        dependencies,
        inheritedAttributes: inheritedAttributes,
      );

      Analytics.trackRender(fragmentName: fragment.qualifiedName);
      return output;
    } catch (e) {
      if (!_wasFragmentErrorTracked) {
        _wasFragmentErrorTracked = true;
        final fragment = _fragmentStack.last;
        Analytics.trackError(fragmentName: fragment.qualifiedName, error: e);
      }
      rethrow;
    } finally {
      _fragmentStack.removeLast();
      if (_fragmentStack.isEmpty) {
        _wasFragmentErrorTracked = false;
      }
    }
  }

  /// Inflates a single XML element into its corresponding Dart object.
  ///
  /// This is the core inflation engine that maps an XML element to a
  /// registered inflater and produces a widget or object of type [T].
  /// The process involves parsing attributes, evaluating visibility,
  /// inflating children, and invoking the matched inflater.
  ///
  /// The inflation pipeline for each element:
  /// 1. Looks up the inflater registered for the element's tag name.
  /// 2. Parses XML attributes and evaluates any data binding expressions.
  /// 3. Injects an analytics observer for render tracking.
  /// 4. Evaluates the `visible` attribute — if `false`, returns `null`
  ///    without inflating the element. If omitted, visibility defaults
  ///    to `true`.
  /// 5. For custom widgets, injects the raw [element] and [dependencies]
  ///    as private attributes (`_element`, `_dependencies`) so the widget
  ///    can manage its own inflation.
  /// 6. Inflates child elements. If the inflater declares that it manages
  ///    its own children, only attribute-referenced children are inflated
  ///    here; the component handles the rest.
  /// 7. Invokes the inflater with the resolved attributes, child objects,
  ///    and any text content.
  ///
  /// Returns `null` if the element is not visible or if an error occurs
  /// during inflation. Errors are logged with a diagnostic dump of the
  /// element and its dependencies, and tracked via analytics with the
  /// fragment file path and source position.
  ///
  /// - [element]: The XML element to inflate.
  /// - [dependencies]: The dependency scope for data binding and
  ///   expression evaluation.
  /// - [inheritedAttributes]: Optional attributes inherited from a parent
  ///   element or fragment boundary, merged during attribute parsing.
  ///
  /// Throws if no inflater is registered for the element's tag name.
  /// All other inflation errors are caught, logged, and return `null`.
  static T? inflateFromXmlElement<T>(
    XmlElement element,
    Dependencies dependencies, {
    Iterable<XmlAttribute>? inheritedAttributes,
  }) {
    try {
      final type = element.localName;
      final inflater = _inflaters[type];
      if (inflater != null) {
        final attributes = parseXmlAttributes(
          element,
          dependencies,
          inflater: inflater,
          inheritedAttributes: inheritedAttributes,
        );

        T? returnValue;
        _injectAnalyticsObserver(inflater, attributes);

        // we only want to evaluate the 'visible' attribute if one was provided;
        // otherwise, the component is visible by default.
        if (!attributes.containsKey("visible") || toBool(attributes["visible"]) == true) {
          // widget is visible, so let's continue
          if (inflater.inflatesCustomWidget) {
            // inflating a custom widget or object, so include the element and
            // dependencies as 'private' attributes.
            attributes["_element"] = element;
            attributes["_dependencies"] = dependencies;
          }
          final children = inflateXmlElementChildren(
            element,
            dependencies,
            // if the component inflates it's own children the we only want to
            // inflate the children the reference attributes so we can pass
            // them to the constructor. THe component is responsible for
            // inflating the remaining children.
            onlyAttributes: inflater.inflatesOwnChildren,
          );
          attributes.addAll(children.attributes);
          returnValue = inflater.inflate(attributes, children.objects, children.text);
        }
        return returnValue;
      }
      throw Exception("XWidget inflater not found for XML element <$type>");
    } catch (e, stacktrace) {
      final msg = "Problem inflating XML element '${element.name}'";
      _log.severe("$msg: ${dump(element, dependencies)}", e, stacktrace);

      // track element inflate error
      final name = element.position?.filePath;
      final tag = element.position?.openTag;
      final line = tag?.start.line;
      final col = tag?.start.column;
      final pos = "[line:$line, col:$col]";
      Analytics.trackError(fragmentName: name, error: "$msg $e $pos");

      return null;
    }
  }

  /// Inflates the children of an XML element and collects the results.
  ///
  /// Iterates over the child nodes of [element] and processes each based
  /// on its type: text nodes, tag elements, and component elements. The
  /// results are collected into a [Children] object containing three
  /// categories:
  ///
  /// - **text**: Raw text and CDATA content from the element body.
  /// - **attributes**: Named child objects designated via the `for`
  ///   attribute, passed to the parent inflater as named constructor
  ///   parameters (e.g. `<Widget for="leading">`).
  /// - **objects**: Unnamed child objects added as positional children.
  ///
  /// Child elements are classified as either *tags* or *components*.
  /// Tags are special directives (e.g. control flow, iteration) that are
  /// processed via [Tag.processTag] and may produce zero or more children.
  /// Components are standard widgets or objects inflated recursively via
  /// [inflateFromXmlElement].
  ///
  /// The filtering parameters control which children are processed:
  ///
  /// - [excludeElements]: Tag names to skip entirely during inflation.
  /// - [excludeText]: If `true`, text and CDATA nodes are ignored.
  /// - [excludeAttributes]: If `true`, children with a `for` attribute
  ///   are skipped.
  /// - [onlyAttributes]: If `true`, only children with a `for` attribute
  ///   are inflated, and text nodes are ignored. Used when a component
  ///   inflates its own children and only needs named attribute children
  ///   resolved upfront.
  ///
  /// - [element]: The parent XML element whose children will be inflated.
  /// - [dependencies]: The dependency scope for data binding and
  ///   expression evaluation.
  static Children inflateXmlElementChildren(
    XmlElement element,
    Dependencies dependencies, {
    Set<String>? excludeElements,
    bool excludeText = false,
    excludeAttributes = false,
    onlyAttributes = false,
  }) {
    final children = Children();
    for (final child in element.children) {
      if (!excludeText && !onlyAttributes && (child is XmlText || child is XmlCDATA)) {
        if (child.value != null && child.value!.isNotEmpty) {
          children.text.add(child.value!);
        }
      } else if (child is XmlElement &&
          shouldInflateXmlElement(
            child,
            excludeElements: excludeElements,
            excludeAttributes: excludeAttributes,
            onlyAttributes: onlyAttributes,
          )) {
        // child is an element and we should inflate it
        final tag = _tags[child.localName];
        if (tag != null) {
          // element is a tag
          final attributes = parseXmlAttributes(child, dependencies);
          final tagChildren = tag.processTag(child, attributes, dependencies);
          children.addAll(tagChildren);
        } else {
          // element is a component
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
    return children;
  }

  static bool shouldInflateXmlElement(
    XmlElement element, {
    Set<String>? excludeElements,
    bool excludeAttributes = false,
    bool onlyAttributes = false,
  }) {
    final elementName = element.localName;
    if (excludeElements == null ||
        excludeElements.isEmpty ||
        !excludeElements.contains(elementName)) {
      if (excludeAttributes || onlyAttributes) {
        final attributeName = element.getAttribute("for");
        final forAttribute = attributeName != null && attributeName.isNotEmpty;
        return (forAttribute && !excludeAttributes) || (!forAttribute && !onlyAttributes);
      }
      return true;
    }
    return false;
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
        final msg = "Problem parsing XML attribute '${attribute.qualifiedName}'";
        _log.severe("$msg: ${dump(element, dependencies)}", e, stacktrace);

        // track xml attribute parsing error
        final name = element.position?.filePath;
        final tag = element.position?.openTag;
        final line = tag?.start.line;
        final col = tag?.start.column;
        final pos = "[line:$line, col:$col]";
        Analytics.trackError(fragmentName: name, error: "$msg: $e $pos");
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
      final value = parseExpression(
        attributeValue.substring(2, attributeValue.length - 1),
        dependencies,
      );
      return (inflater != null && value is String)
          ? inflater.parseAttribute(attributeName, value)
          : value;
    }
    if (attributeValue.startsWith("@")) {
      // possible directive
      if (attributeValue.startsWith("@color/")) {
        final param = attributeValue.substring(7, attributeValue.length);
        return Resources.instance.getColor(param);
      }
      if (attributeValue.startsWith("@string/")) {
        final param = attributeValue.substring(8, attributeValue.length);
        return Resources.instance.getString(param);
      }
      if (attributeValue.startsWith("@bool/")) {
        final param = attributeValue.substring(6, attributeValue.length);
        return Resources.instance.getBool(param);
      }
      if (attributeValue.startsWith("@int/")) {
        final param = attributeValue.substring(5, attributeValue.length);
        return Resources.instance.getInt(param);
      }
      if (attributeValue.startsWith("@double/")) {
        final param = attributeValue.substring(8, attributeValue.length);
        return Resources.instance.getDouble(param);
      }
    }

    final value = parseAllExpressions(attributeValue, dependencies);
    return (inflater != null) ? inflater.parseAttribute(attributeName, value) : value;
  }

  static Iterable<XmlAttribute> mergeXmlAttributes(
    Iterable<XmlAttribute> list1,
    Iterable<XmlAttribute>? list2,
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
    return elParser.evaluate(expression, dependencies);
  }

  static Fragment getFragment(String name) {
    String requestedName;
    String qualifiedName;
    Map<String, String> queryParams;
    XmlDocument? xmlDocument;

    final splitIndex = name.indexOf("?");
    if (splitIndex > -1) {
      // process params in name
      requestedName = name.substring(0, splitIndex).trim();
      final query = name.substring(splitIndex + 1).trim();
      queryParams = query.isNotEmpty ? Uri.splitQueryString(query) : {};
    } else {
      requestedName = name.trim();
      queryParams = {};
    }

    qualifiedName = Resources.instance.getFragmentFqn(requestedName);
    if (xmlCacheEnabled) xmlDocument = _xmlCache[qualifiedName];

    if (xmlDocument == null) {
      final xmlString = Resources.instance.getFragment(qualifiedName);
      xmlDocument = XmlParser.parse(
        SourceCode(xmlString, filePath: qualifiedName, withPosition: true),
      );
      if (xmlCacheEnabled) _xmlCache[qualifiedName] = xmlDocument;
    }

    return Fragment(
      requestedName: requestedName,
      qualifiedName: qualifiedName,
      queryParams: queryParams,
      xmlDocument: xmlDocument,
    );
  }

  static Dependencies scopeDependencies(
    XmlElement element,
    Dependencies dependencies,
    String? scope, [
    String defaultScope = "inherit",
  ]) {
    if (isEmpty(scope)) {
      scope = defaultScope;
      for (final child in element.children) {
        if (child is XmlElement && child.localName == "var") {
          scope = "copy";
        }
      }
    }
    switch (scope) {
      case "new":
        return Dependencies();
      case "copy":
        return dependencies.copy();
      case "inherit":
        return dependencies;
      default:
        throw Exception("Invalid Dependencies scope '$scope'");
    }
  }

  static String dump(XmlElement element, Dependencies dependencies) {
    return "\n----- XML Element -----\n${element.toXmlString(pretty: true)}"
        "\n----- Dependencies -----\n$dependencies";
  }

  static void _injectAnalyticsObserver(Inflater inflater, Map<String, dynamic> attributes) {
    if (!Analytics.isInitialized) return;

    final key = switch (inflater.type) {
      'MaterialApp' || 'CupertinoApp' || 'WidgetsApp' => 'navigatorObservers',
      'Navigator' => 'observers',
      _ => null,
    };

    if (key != null) {
      final observers = List<NavigatorObserver>.from(
        attributes[key] as List<NavigatorObserver>? ?? [],
      );
      observers.add(AnalyticsNavigatorObserver());
      attributes[key] = observers;
    }
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

  void addAll(Children? children) {
    if (children != null) {
      text.addAll(children.text);
      objects.addAll(children.objects);
      attributes.addAll(children.attributes);
    }
  }

  List<Widget> getWidgets() {
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

//===================================
// Abstract Classes
//===================================

/// The base class for all inflaters.
///
/// While it's possible to manually create an inflater by implementing this
/// class, the best practice is to use the @InflaterDef annotation on your
/// class and let XWidget generate the inflater by running
/// `dart run xwidget_builder:generate`.
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
  T? inflate(Map<String, dynamic> attributes, List<dynamic> children, List<String> text);

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
    Dependencies dependencies,
  );
}

class Fragment {
  String requestedName;
  String qualifiedName;
  Map<String, String> queryParams;
  XmlDocument xmlDocument;

  Fragment({
    required this.requestedName,
    required this.qualifiedName,
    required this.queryParams,
    required this.xmlDocument,
  });
}

class FragmentPlaceholder extends Fragment {
  static final doc = XmlDocument();

  FragmentPlaceholder({required super.requestedName})
    : super(qualifiedName: '', queryParams: const {}, xmlDocument: doc);
}
