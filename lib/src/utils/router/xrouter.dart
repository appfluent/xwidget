import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';

import '../../../xwidget.dart';
import 'web_url_sync.dart';

/// Callback invoked when the route changes. Used by the web sync
/// layer to update the browser URL.
typedef UrlSyncCallback = void Function(String path);

/// Callback invoked by the router to change the visible page in a
/// multi-view widget. The implementation determines the widget type:
/// [PageController.jumpToPage] for PageView, [State.setState] with an
/// index for IndexedStack, [TabController.animateTo] for TabBarView.
typedef RouteCallback = void Function(int index, String? name, Map<String, dynamic> params);

/// The result of resolving a navigation target to a route.
///
/// Contains all the information needed to identify, render, and
/// track the resolved destination. Parameters from the path,
/// query string, and caller are merged into a single [params] map.
class ResolvedRoute {
  /// effective navigation target
  final String target;

  /// The URL path for this route (e.g. "/analytics/overview").
  final String path;

  /// The fragment to inflate when this route is active.
  final String fragment;

  /// Optional name for programmatic reference.
  final String? name;

  /// The name of the group this route belongs to, or null for
  /// standalone routes.
  final String? groupName;

  /// Whether this route pushes to browser history when navigated
  /// to. Inherited from the route group when not set explicitly.
  final bool history;

  /// The index of this route within its group. Null for standalone
  /// routes.
  final int? viewIndex;

  /// Merged parameters from path segments, query string, and
  /// caller-provided values.
  final Map<String, String> params;

  const ResolvedRoute({
    required this.target,
    required this.path,
    required this.fragment,
    this.name,
    this.groupName,
    this.viewIndex,
    this.history = true,
    this.params = const {},
  });

  String get targetPath => target.startsWith('/') ? target : path;

  @override
  String toString() => 'ResolvedRoute($path, params=$params)';
}

/// Minimal singleton router for XWidget applications.
///
/// Manages a route map, binds multi-view widgets (e.g. PageView)
/// to route groups, provides context-free navigation via [goTo],
/// and tracks navigation events for analytics.
///
/// ## Initialization
///
/// Call [loadRoutesFromXml] during app startup to populate the
/// route map from parsed `routes.xml` definitions:
///
/// ```dart
/// await XWidget.initialize(...);
/// XRouter.loadRoutesFromXml(routesXmlDocument);
/// ```
///
/// ## View Registration
///
/// Controllers that own a multi-view widget register a callback
/// with the router so that [goTo] can switch to the correct page:
///
/// ```dart
/// XRouter.registerView('main', (index, name, params) {
///   pageController.jumpToPage(index);
/// });
/// ```
///
/// ## Navigation
///
/// Navigate from anywhere — controllers, EL expressions, callbacks
/// — without requiring a [BuildContext]:
///
/// ```dart
/// XRouter.goTo('/analytics/renders');
/// XRouter.goTo('/login', action: NavigatorAction.pushAndRemoveAll);
/// ```
///
/// ## Route Types
///
/// XRouter supports two types of routes:
///
/// - **Navigator routes**: Routes that push fragments onto
///   Flutter's Navigator stack. Can be standalone or grouped.
///
/// - **Callback routes**: Grouped routes that drive a multi-page
///   widget such as PageView, TabBarView, or IndexedStack.
///   Instead of pushing onto the Navigator, these routes invoke
///   a registered callback that switches the active page.
class XRouter {
  XRouter._();

  static final _log = Logger("XRouter");

  /// All routes (grouped and standalone), keyed by path, name,
  /// and aliases.
  static final Map<String, _Route> _routes = {};

  /// Compiled patterns for routes with path parameters.
  static final List<_RoutePattern> _routePatterns = [];

  /// Registered view callbacks, keyed by group name.
  static final Map<String, RouteCallback> _callbacks = {};

  /// The currently active resolved route, or null before first
  /// navigation.
  static ResolvedRoute? _currentRoute;

  /// Callback fired when the URL should be updated. Set by the
  /// web sync layer; null on non-web platforms.
  static UrlSyncCallback? onUrlChanged;

  static bool _initialBrowserLocationApplyScheduled = false;

  static bool _initialBrowserLocationApplied = false;

  static final _sourceMap = <String, Set<_Route>>{};

  // ===================================
  // Initialization
  // ===================================

  /// Populates the router from a parsed routes XML document.
  ///
  /// Parses `<routeGroup>` and standalone `<route>` elements from
  /// the document's `<routes>` root. Call once during app startup
  /// after [XWidget.initialize].
  static void loadRoutesFromXml(String source, XmlDocument document) {
    _removeRoutes(source);

    final root = document.getElement('routes');
    if (root == null) return;

    for (final element in root.childElements) {
      switch (element.name.qualified) {
        case 'routeGroup':
          final routes = _parseRouteGroup(element);
          for (final route in routes) {
            _registerRoute(source, route);
          }
        case 'route':
          _registerRoute(source, _parseRoute(element));
      }
    }
  }

  // ===================================
  // View Registration
  // ===================================

  /// Registers a [RouteCallback] for a route group.
  ///
  /// The callback receives a page index, the route's name, and
  /// merged parameters. It is responsible for updating the
  /// multi-view widget and handling any parameter changes:
  ///
  /// ```dart
  /// // PageView
  /// XRouter.registerRouteCallback('main', (index, name, params) {
  ///   pageController.jumpToPage(index);
  /// });
  ///
  /// // IndexedStack
  /// XRouter.registerRouteCallback('main', (index, name, params) {
  ///   setState(() => currentIndex = index);
  /// });
  ///
  /// // TabBarView
  /// XRouter.registerRouteCallback('main', (index, name, params) {
  ///   tabController.animateTo(index);
  /// });
  /// ```
  static void registerRouteCallback(String groupName, RouteCallback callback) {
    _callbacks[groupName] = callback;
    WebUrlSync.enable();

    // After this view group is ready, try to honor the browser URL.
    _scheduleInitialBrowserLocationApply();
  }

  /// Unregisters a view callback for a route group.
  ///
  /// Call in the controller's [State.dispose] method.
  static void unregisterRouteCallback(String groupName) {
    _callbacks.remove(groupName);
  }

  /// Returns true if a view callback is registered for the given
  /// group name.
  static bool hasRegisteredView(String groupName) {
    return _callbacks.containsKey(groupName);
  }

  // ===================================
  // Navigation
  // ===================================

  /// Navigates to a route by path or name.
  ///
  /// For grouped routes, invokes the registered [RouteCallback]
  /// with the route's view index, name, and merged parameters.
  /// For standalone routes, inflates the fragment and pushes it
  /// onto the [Navigator] using the specified [action].
  ///
  /// Tracks the navigation event via [Analytics.trackNavigation]
  /// on every call. Updates the browser URL via [onUrlChanged]
  /// for routes that have [ResolvedRoute.history] enabled.
  ///
  /// [target] can be a path (e.g. "/analytics/renders") or a
  /// named route (e.g. "main:renders").
  ///
  /// [dependencies] provides the dependency scope for fragment
  /// inflation on standalone routes.
  ///
  /// [action] controls the navigation style for standalone routes.
  /// Ignored for grouped routes. Defaults to [NavigatorAction.push].
  ///
  /// [params] are merged with any path or query parameters
  /// extracted during route resolution and passed to both grouped
  /// and standalone routes.
  static void goTo(
    String target, {
    Dependencies? dependencies,
    NavigatorAction action = NavigatorAction.push,
    Map<String, dynamic>? params,
  }) {
    _log.info('goTo: target=$target');

    final resolved = resolve(target);
    if (resolved == null) {
      _log.warning('No route found for "$target"');
      return;
    }

    // final previous = _currentRoute;
    _currentRoute = resolved;

    // send analytics event
    Analytics.trackNavigation(pageName: resolved.path);

    // navigate to route
    _navigateToRoute(resolved, dependencies: dependencies, params: params, action: action);
  }

  static void routeTo(String target, [String? action]) {
    final navAction = parseEnum(NavigatorAction.values, action);
    goTo(target, action: navAction ?? NavigatorAction.push);
  }

  static void routePop() {
    final navigator = XWidget.navigatorKey.currentState;
    navigator?.pop();
  }

  static void routePopAll() {
    final navigator = XWidget.navigatorKey.currentState;
    navigator?.popUntil((route) => route.isFirst);
  }

  /// Resolves a target string to a [ResolvedRoute].
  ///
  /// Targets starting with `/`, `https://`, or `http://` are
  /// treated as paths — query parameters are stripped before
  /// matching and included in the resolved route's [params].
  /// All other targets are treated as names and matched directly
  /// against the route map without parsing.
  ///
  /// Resolution order for paths: exact path match, then pattern
  /// match against parameterized routes. For names: exact match
  /// against registered names and aliases. Returns null if no
  /// match is found.
  static ResolvedRoute? resolve(String target) {
    final isPath =
        target.startsWith('/') || target.startsWith('https://') || target.startsWith('http://');

    if (isPath) {
      final uri = Uri.parse(target);
      final path = uri.path.replaceAll(RegExp(r'/+'), '/');
      final queryParams = uri.queryParameters;
      final pathAndQuery = uri.hasQuery ? '$path?${uri.query}' : path;

      // Exact path match
      final route = _routes[path];
      if (route != null) return _toResolved(pathAndQuery, route, params: queryParams);

      // Pattern match against parameterized routes
      for (final pattern in _routePatterns) {
        final match = pattern.regExp.firstMatch(path);
        if (match == null) continue;

        final pathParams = <String, String>{};
        for (var i = 0; i < pattern.paramNames.length; i++) {
          pathParams[pattern.paramNames[i]] = match.group(i + 1)!;
        }
        return _toResolved(pathAndQuery, pattern.route, params: {...pathParams, ...queryParams});
      }
    } else {
      // Exact name match
      final exactRoute = _routes[target];
      if (exactRoute != null) return _toResolved(target, exactRoute);
    }

    return null;
  }

  /// The currently active resolved route, or null before first
  /// navigation.
  static ResolvedRoute? get currentRoute => _currentRoute;

  // ===================================
  // Private Methods
  // ===================================

  static ResolvedRoute _toResolved(
    String target,
    _Route route, {
    Map<String, String> params = const {},
  }) {
    return ResolvedRoute(
      target: target,
      path: route.path,
      fragment: route.fragment,
      name: route.name,
      groupName: route.groupName,
      viewIndex: route.viewIndex,
      history: route.history,
      params: {...params},
    );
  }

  static void _navigateToRoute(
    ResolvedRoute resolved, {
    Dependencies? dependencies,
    NavigatorAction action = NavigatorAction.push,
    Map<String, dynamic>? params,
    bool updateUrl = true,
  }) {
    final mergedParams = <String, dynamic>{...resolved.params, ...?params};
    final callback = resolved.groupName != null ? _callbacks[resolved.groupName] : null;

    if (callback != null) {
      callback(resolved.viewIndex ?? 0, resolved.name, mergedParams);
    } else {
      XWidget.navigateToFragment(
        resolved.fragment,
        dependencies ?? Dependencies(),
        pageName: resolved.path,
        params: mergedParams,
        action: action,
      );
    }

    if (updateUrl && resolved.history) {
      onUrlChanged?.call(resolved.targetPath);
    }
  }

  /// Registers a route in the lookup maps and builds a compiled
  /// pattern if the path contains parameter segments.
  ///
  /// Each route is registered under its path and optionally its
  /// name and aliases. Throws if any key collides with an existing
  /// registration.
  static void _registerRoute(String source, _Route route) {
    // register route by path
    if (_routes.containsKey(route.path)) {
      throw Exception('Route path "${route.path}" already exists');
    }
    _routes[route.path] = route;

    // register route by name
    if (route.name != null) {
      if (_routes.containsKey(route.name)) {
        throw Exception('Route name "${route.name}" already exists');
      }
      _routes[route.name!] = route;
    }

    // register routes by aliases
    for (final alias in route.aliases) {
      if (_routes.containsKey(alias)) {
        throw Exception('Route name or path collision: "$alias"');
      }
      _routes[alias] = route;
    }

    // Build pattern for parameterized paths
    if (route.path.contains(':')) {
      final regexStr = route.path.replaceAllMapped(RegExp(r':(\w+)'), (m) => r'([^/]+)');
      final paramNames = RegExp(r':(\w+)').allMatches(route.path).map((m) => m.group(1)!).toList();
      _routePatterns.add(
        _RoutePattern(route: route, regExp: RegExp('^$regexStr\$'), paramNames: paramNames),
      );
    }

    // add route to source map
    (_sourceMap[source] ??= {}).add(route);
  }

  static void _scheduleInitialBrowserLocationApply() {
    if (_initialBrowserLocationApplied || _initialBrowserLocationApplyScheduled) return;

    _initialBrowserLocationApplyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialBrowserLocationApplyScheduled = false;
      _applyInitialBrowserLocationIfReady();
    });
  }

  static void _applyInitialBrowserLocationIfReady() {
    if (_initialBrowserLocationApplied) return;

    final resolved = resolve(WebUrlSync.currentPath);
    if (resolved == null) return;

    if (resolved.groupName != null && !_callbacks.containsKey(resolved.groupName)) {
      return;
    }

    _initialBrowserLocationApplied = true;
    _currentRoute = resolved;
    _navigateToRoute(resolved, updateUrl: false);
  }

  // ===================================
  // XML Parsing
  // ===================================

  /// Parses a `<routeGroup>` element into a list of [_Route]
  /// objects with shared group properties.
  ///
  /// Group attributes (`path`, `history`) propagate to child
  /// routes as defaults. The first route in document order serves
  /// as the group's default and receives aliases for the group
  /// name and group path.
  static List<_Route> _parseRouteGroup(XmlElement element) {
    final groupName = element.getAttribute('name');
    if (groupName == null || groupName.isEmpty) {
      throw Exception("routeGroup requires a 'name' attribute");
    }

    final groupPath = element.getAttribute('path');
    if (groupPath != null) {
      if (!groupPath.startsWith('/')) {
        throw Exception("routeGroup 'path' must begin with a slash (/)");
      }
      if (groupPath.contains(RegExp(r'//')) || (groupPath.length > 1 && groupPath.endsWith('/'))) {
        throw Exception("route path '$groupPath' contains extra or trailing slashes");
      }
    }

    final groupHistory = tryParseBool(element.getAttribute('history')) ?? true;

    var index = 0;
    final routes = <_Route>[];
    for (final child in element.childElements) {
      if (child.name.qualified == 'route') {
        final route = _parseRoute(
          child,
          groupName: groupName,
          groupPath: groupPath,
          groupHistory: groupHistory,
          viewIndex: index,
        );
        routes.add(route);
        index++;
      }
    }

    // set aliases on group default route
    if (routes.isNotEmpty) {
      final defaultRoute = routes.first;
      defaultRoute.aliases.add(groupName);
      if (groupPath != null && groupPath.isNotEmpty) {
        defaultRoute.aliases.add(groupPath);
      }
    }

    return routes;
  }

  /// Parses a `<route>` element into a [_Route] object.
  ///
  /// When called within a route group, inherits the group's name
  /// prefix, path prefix, and history setting as defaults. Route-
  /// level attributes override group defaults when present.
  static _Route _parseRoute(
    XmlElement element, {
    String? groupName,
    String? groupPath,
    bool groupHistory = true,
    int? viewIndex,
  }) {
    final path = element.getAttribute('path');
    if (path == null || path.isEmpty) {
      throw Exception("route requires a 'path' attribute");
    }
    if (!path.startsWith('/')) {
      throw Exception("route 'path' must begin with a slash (/)");
    }
    if (path.contains(RegExp(r'//')) || (path.length > 1 && path.endsWith('/'))) {
      throw Exception("route path '$path' contains extra or trailing slashes");
    }
    final fragment = element.getAttribute('fragment');
    if (fragment == null || fragment.isEmpty) {
      throw Exception("route '$path' requires a 'fragment' attribute");
    }

    final name = element.getAttribute('name');

    final fullPath = (groupPath != null) ? '$groupPath$path'.replaceAll(RegExp(r'/+'), '/') : path;
    final fullName = (groupName != null && name != null) ? '$groupName:$name' : name;
    final history = tryParseBool(element.getAttribute('history')) ?? groupHistory;

    return _Route(
      name: fullName,
      path: fullPath,
      fragment: fragment,
      groupName: groupName,
      history: history,
      viewIndex: viewIndex,
    );
  }

  static void _removeRoutes(String source) {
    final routes = _sourceMap[source] ?? {};
    _routes.removeWhere((_, value) => routes.contains(value));
    _routePatterns.removeWhere((p) => routes.contains(p.route));
  }
}

// =============================================================================
// Private Data Models
// =============================================================================

/// A single route definition.
class _Route {
  final String? name;
  final String path;
  final String fragment;
  final String? groupName;
  final bool history;
  final int? viewIndex;
  final List<String> aliases = [];

  _Route({
    this.name,
    required this.path,
    required this.fragment,
    this.groupName,
    this.history = true,
    this.viewIndex,
  });
}

/// Compiled pattern for a parameterized route.
class _RoutePattern {
  final _Route route;
  final RegExp regExp;
  final List<String> paramNames;

  const _RoutePattern({required this.route, required this.regExp, required this.paramNames});
}
