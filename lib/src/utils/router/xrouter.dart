import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:xml/xml.dart';
import 'package:xwidget_el/xwidget_el.dart';

import '../../analytics/analytics.dart';
import '../../xwidget.dart';
import 'web_url_sync.dart';

enum NavigatorAction { push, pushReplacement, pushAndRemoveUntil, pushAndRemoveAll }

/// Callback invoked by the router to change the visible page in a
/// multi-view widget. The implementation determines the widget type:
/// [PageController.jumpToPage] for PageView, [State.setState] with an
/// index for IndexedStack, [TabController.animateTo] for TabBarView.
typedef RouteCallback = void Function(int index, String? name, Map<String, dynamic> params);

/// Opens a route's fragment in a custom presentation (dialog, sheet, …).
typedef RoutePresenter =
    void Function(ResolvedRoute route, Dependencies dependencies, Map<String, dynamic> params);

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

  final String? presenter;

  final String? transition;

  /// The index of this route within its group. Null for standalone
  /// routes.
  final int? viewIndex;

  /// Merged parameters from path segments, query string, and
  /// caller-provided values.
  final Map<String, dynamic> params;

  /// Parent group activations required before this route's own
  /// group is on screen, ordered outermost first.
  final List<RouteActivation> ancestors;

  const ResolvedRoute({
    required this.target,
    required this.path,
    required this.fragment,
    this.name,
    this.groupName,
    this.viewIndex,
    this.history = true,
    this.presenter,
    this.transition,
    this.params = const {},
    this.ancestors = const [],
  });

  // String get targetPath => target.startsWith('/') ? target : path;

  @override
  String toString() => 'ResolvedRoute($path, name=$name, presenter=$presenter, params=$params, )';
}

/// A single step in the ancestor activation chain for nested
/// route groups.
///
/// When a route belongs to a nested group, each ancestor
/// describes which parent group must be activated (and at which
/// view index) before the route's own group is on screen.
class RouteActivation {
  final String groupName;
  final int viewIndex;
  final String? name;
  final String? path;
  final String? fragment;
  final String? transition;

  const RouteActivation({
    required this.groupName,
    required this.viewIndex,
    this.path,
    this.fragment,
    this.name,
    this.transition,
  });

  @override
  String toString() => 'RouteActivation($groupName[$viewIndex], path=$path)';
}

class XRouterRouteSettings extends RouteSettings {
  final bool sendTrackingAnalytics;
  const XRouterRouteSettings({super.name, super.arguments, this.sendTrackingAnalytics = true});
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

  /// Last navigated target per group, for resuming the active
  /// tab when returning to a group via alias.
  static final Map<String, String> _lastGroupRoute = {};

  static bool _pendingRouteScheduled = false;

  static bool _initialRouteProcessed = false;

  static _PendingRoute? _pendingRoute;

  static final int _defaultMaxRedirects = 5;

  static final Map<String, RoutePresenter> _presenters = {
    'dialog': _dialogPresenter,
    'bottomSheet': _bottomSheetPresenter,
  };

  static final _sourceMap = <String, Set<_Route>>{};

  /// The currently active resolved route, or null before first
  /// navigation.
  static ResolvedRoute? get currentRoute => _currentRoute;

  /// Global navigator key. Assign to [MaterialApp.navigatorKey]
  /// to enable context-free navigation for routes.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static int maxRedirects = _defaultMaxRedirects;

  // ===================================
  // Initialization
  // ===================================

  /// Populates the router from a parsed routes XML document.
  ///
  /// Parses `<routeGroup>` and standalone `<route>` elements from
  /// the document's `<routes>` root. Call once during app startup
  /// after [XWidget.initialize].
  static void loadRoutesFromXml(String source, XmlDocument document) {
    // Match the root by local name so namespace-prefixed documents
    // (<r:routes xmlns:r="...">) load the same as default-namespace ones.
    final root = document.rootElement.name.local == 'routes' ? document.rootElement : null;
    if (root == null) return;

    final newMaxRedirects = tryParseInt(root.getAttribute('maxRedirects')) ?? _defaultMaxRedirects;

    // Loads are atomic: parse and collision-check the entire document before
    // touching live state, so a bad document (validation error, duplicate
    // path/name) changes nothing — the previous routes stay registered and
    // resolvable. Matters for hot reload and OTA updates, where a failed
    // load must not leave partial or orphaned routes behind.

    // Phase 1: parse. Throws leave everything untouched.
    final parsed = <_Route>[];
    for (final element in root.childElements) {
      switch (element.name.local) {
        case 'routeGroup':
          parsed.addAll(_parseRouteGroup(element));
        case 'route':
          parsed.add(_parseRoute(element));
      }
    }

    // Phase 2: validate collisions against a staged view of the route map
    // with this source's old routes removed — a reload may reuse its keys.
    final oldRoutes = _sourceMap[source] ?? {};
    final staged = Map.of(_routes)..removeWhere((_, route) => oldRoutes.contains(route));
    for (final route in parsed) {
      _stageRoute(staged, route);
    }

    // Phase 3: commit. Cannot throw — the same inserts just validated
    // against the same effective baseline.
    _removeRoutes(source);
    for (final route in parsed) {
      _registerRoute(source, route);
    }
    maxRedirects = newMaxRedirects;
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
    _schedulePendingRouteProcessing();
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

  /// Registers a presentation handler. Apps/packages call this to add
  /// their own (e.g. xwidget_ui registering 'sidePanel').
  static void registerPresenter(String name, RoutePresenter presenter) {
    _presenters[name] = presenter;
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
  /// on every call. Routes with [ResolvedRoute.history] enabled update the
  /// browser URL when navigation is processed.
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

    // If target matches a group alias and the group has a
    // previously active route, resume that route instead of
    // navigating to the default child.
    final lookupKey = target.startsWith('/') ? _TargetUri.parse(target).path : target;
    final aliasRoute = _routes[lookupKey];
    if (aliasRoute != null &&
        aliasRoute.groupName != null &&
        aliasRoute.aliases.contains(lookupKey)) {
      final lastTarget = _lastGroupRoute[aliasRoute.groupName!];
      if (lastTarget != null) {
        target = lastTarget;
      }
    }

    final resolved = resolve(target);
    if (resolved == null) {
      _log.warning('No route found for "$target"');
      return;
    }

    // If the route has ancestors, use the cascade mechanism
    if (resolved.ancestors.isNotEmpty) {
      _pendingRoute = _PendingRoute(
        resolved: resolved,
        dependencies: dependencies,
        action: action,
        params: params,
        urlUpdate: _UrlUpdate.push,
        remainingAncestors: [...resolved.ancestors],
      );
      _processPendingRoute();
      return;
    }

    // No ancestors — navigate directly
    _navigateToRoute(resolved, dependencies: dependencies, params: params, action: action);
  }

  static void routeTo(String target, [String? action]) {
    final navAction = parseEnum(NavigatorAction.values, action);
    goTo(target, action: navAction ?? NavigatorAction.push);
  }

  static void routePop() {
    final navigator = navigatorKey.currentState;
    navigator?.pop();
  }

  static void routePopAll() {
    final navigator = navigatorKey.currentState;
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
    return _resolveRoute(target);
  }

  /// Navigates to a fragment-backed page by inflating an XML fragment
  /// and pushing the resulting widget onto the navigation stack.
  ///
  /// Inflates the fragment specified by [fragmentName] into a widget and
  /// navigates using either a [MaterialPageRoute] or [CupertinoPageRoute].
  /// The navigation behavior is determined by [action]:
  ///
  /// - [NavigatorAction.push] — adds the route on top of the stack.
  /// - [NavigatorAction.pushReplacement] — replaces the current route.
  /// - [NavigatorAction.pushAndRemoveAll] — pushes the route and removes
  ///   all previous routes from the stack.
  ///
  /// The route name defaults to [fragmentName] unless [pageName] is
  /// provided, which is useful for analytics tracking and route-aware
  /// widgets like [NavigatorObserver].
  ///
  /// Example:
  /// ```dart
  /// XWidget.navigateToFragment(
  ///   'screens/settings',
  ///   dependencies,
  ///   pageName: '/settings',
  ///   params: {'userId': currentUser.id},
  ///   action: NavigatorAction.pushReplacement,
  /// );
  /// ```
  ///
  /// - [fragmentName]: The name of the fragment resource to inflate.
  /// - [dependencies]: The dependency scope for data binding and
  ///   expression evaluation within the fragment.
  /// - [pageName]: Optional route name for the [RouteSettings]. Defaults
  ///   to [fragmentName] if omitted.
  /// - [params]: Optional key-value pairs passed to the fragment during
  ///   inflation. See [XWidget.inflateFragment] for details on parameter
  ///   handling.
  /// - [transition]: 'none', 'fade', 'slide', 'scale', 'cupertino',
  ///    defaults to Material
  ///   [MaterialPageRoute].
  /// - [action]: The navigation action to perform. Defaults to
  ///   [NavigatorAction.push].
  static void navigateToFragment(
    String fragmentName,
    Dependencies dependencies, {
    BuildContext? context,
    String? pageName,
    Map<String, dynamic>? params,
    String? transition,
    RoutePredicate? removeUntil,
    bool sendTrackingAnalytics = true,
    NavigatorAction action = NavigatorAction.push,
  }) {
    if (action == NavigatorAction.pushAndRemoveUntil && removeUntil == null) {
      throw ArgumentError(
        'removeUntil predicate is required '
        'with NavigatorAction.pushAndRemoveUntil',
      );
    }

    final navigator = context != null ? Navigator.of(context) : navigatorKey.currentState;
    if (navigator == null) {
      throw Exception(
        'Navigator not found. Assign XWidget.navigatorKey to'
        ' MaterialApp or CupertinoApp for context-free navigation.',
      );
    }

    final settings = XRouterRouteSettings(
      name: pageName ?? fragmentName,
      sendTrackingAnalytics: sendTrackingAnalytics,
    );

    builder(_) => XWidget.inflateFragment(fragmentName, dependencies, params: params) as Widget;
    final route = _buildRoute(transition, settings, builder);

    switch (action) {
      case NavigatorAction.push:
        navigator.push(route);
      case NavigatorAction.pushReplacement:
        navigator.pushReplacement(route);
      case NavigatorAction.pushAndRemoveUntil:
        navigator.pushAndRemoveUntil(route, removeUntil!);
      case NavigatorAction.pushAndRemoveAll:
        navigator.pushAndRemoveUntil(route, (_) => false);
    }
  }

  // ===================================
  // Private Methods
  // ===================================

  /// Registers a route in the lookup maps and builds a compiled
  /// pattern if the path contains parameter segments.
  ///
  /// Each route is registered under its path and optionally its
  /// name and aliases. Throws if any key collides with an existing
  /// registration.
  /// Inserts a route into [routes] by path, name, and aliases, throwing on
  /// any key collision. Used against the staging map to validate a document
  /// before commit, and against the live map during commit.
  static void _stageRoute(Map<String, _Route> routes, _Route route) {
    // register route by path
    if (routes.containsKey(route.path)) {
      throw Exception('Route path "${route.path}" already exists');
    }
    routes[route.path] = route;

    // register route by name
    if (route.name != null) {
      if (routes.containsKey(route.name)) {
        throw Exception('Route name "${route.name}" already exists');
      }
      routes[route.name!] = route;
    }

    // register routes by aliases
    for (final alias in route.aliases) {
      if (routes.containsKey(alias)) {
        throw Exception('Route name or path collision: "$alias"');
      }
      routes[alias] = route;
    }
  }

  static void _registerRoute(String source, _Route route) {
    _stageRoute(_routes, route);

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

  static void _navigateToRoute(
    ResolvedRoute resolved, {
    Dependencies? dependencies,
    NavigatorAction action = NavigatorAction.push,
    Map<String, dynamic>? params,
    _UrlUpdate urlUpdate = _UrlUpdate.push,
    bool sendTrackingAnalytics = true,
  }) {
    _log.fine(
      '_navigateToRoute: '
      'resolved=$resolved, '
      'urlUpdate=$urlUpdate, '
      'sendTrackingAnalytics=$sendTrackingAnalytics',
    );

    final deps = dependencies ?? Dependencies();
    final mergedParams = <String, dynamic>{...resolved.params, ...?params};
    final presenter = resolved.presenter != null ? _presenters[resolved.presenter] : null;
    final callback = resolved.groupName != null ? _callbacks[resolved.groupName] : null;

    // send analytics event
    if (sendTrackingAnalytics) {
      Analytics.trackNavigation(pageName: resolved.path);
    }

    // we can't accurately manage previous routes for overlay routes because
    // XRouter and Navigator are not synced. Need to switch to N2.0 routes.
    final managed = presenter == null;
    if (managed) {
      _currentRoute = resolved;
      if (resolved.groupName != null) {
        _lastGroupRoute[resolved.groupName!] = resolved.target;
      }
    }

    if (presenter != null) {
      presenter(resolved, deps, mergedParams);
    } else if (callback != null) {
      callback(resolved.viewIndex ?? 0, resolved.name, mergedParams);
    } else {
      navigateToFragment(
        resolved.fragment,
        deps,
        pageName: resolved.path,
        params: mergedParams,
        transition: resolved.transition,
        action: action,
        sendTrackingAnalytics: !sendTrackingAnalytics,
      );
    }

    if (resolved.history && managed) {
      if (urlUpdate == _UrlUpdate.push) {
        WebUrlSync.pushUrl(resolved.target);
      } else if (urlUpdate == _UrlUpdate.replace) {
        WebUrlSync.replaceUrl(resolved.target);
      }
    }
  }

  static Route<T> _buildRoute<T>(
    String? transition,
    XRouterRouteSettings settings,
    WidgetBuilder builder,
  ) {
    switch (transition) {
      case 'none':
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (c, a, s) => builder(c),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      case 'fade':
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (c, a, s) => builder(c),
          transitionsBuilder: (c, a, s, child) => FadeTransition(opacity: a, child: child),
        );
      case 'slide':
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (c, a, s) => builder(c),
          transitionsBuilder: (c, a, s, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
            child: child,
          ),
        );
      case 'scale':
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (c, a, s) => builder(c),
          transitionsBuilder: (c, a, s, child) => ScaleTransition(scale: a, child: child),
        );
      case 'cupertino':
        return CupertinoPageRoute<T>(settings: settings, builder: builder);
      default: // 'default', null, '', unknown → current behavior
        return MaterialPageRoute<T>(settings: settings, builder: builder);
    }
  }

  static ResolvedRoute? _resolveRoute(
    String target, {
    Map<String, dynamic> params = const {},
    int redirectCount = 0,
  }) {
    if (redirectCount > maxRedirects) {
      throw Exception('Too many redirects resolving $target');
    }

    final isPath =
        target.startsWith('/') || target.startsWith('https://') || target.startsWith('http://');

    if (isPath) {
      final uri = _TargetUri.parse(target);

      // Exact path match
      final route = _routes[uri.path];
      if (route != null) {
        final redirect = route.redirect;
        return redirect != null && redirect.isNotEmpty
            ? _resolveRoute(
                uri.buildTargetPath(redirect),
                params: params,
                redirectCount: redirectCount + 1,
              )
            : _toResolvedRoute(
                uri.buildTargetPath(route.path),
                route,
                params: {...params, ...uri.queryParameters},
              );
      }

      // Pattern match against parameterized routes
      for (final pattern in _routePatterns) {
        final match = pattern.regExp.firstMatch(uri.path);
        if (match == null) continue;

        final redirect = pattern.route.redirect;
        return redirect != null && redirect.isNotEmpty
            ? _resolveRoute(
                uri.buildTargetPath(redirect, pattern),
                params: params,
                redirectCount: redirectCount + 1,
              )
            : _toResolvedRoute(
                uri.buildTargetPath(pattern.route.path, pattern),
                pattern.route,
                params: {
                  ...params,
                  ...uri.queryParameters,
                  ...pattern.paramNames.asMap().map(
                    (i, name) => MapEntry(name, match.group(i + 1)!),
                  ),
                },
              );
      }
    } else {
      // Exact name match - does not support path or query params
      final route = _routes[target];
      if (route != null) {
        final redirect = route.redirect;
        return redirect != null && redirect.isNotEmpty
            ? _resolveRoute(redirect, params: params, redirectCount: redirectCount + 1)
            : _toResolvedRoute(route.path, route, params: params);
      }
    }
    return null;
  }

  static ResolvedRoute? _toResolvedRoute(
    String target,
    _Route route, {
    Map<String, dynamic> params = const {},
  }) {
    final fragment = route.fragment;
    if (fragment != null && fragment.isNotEmpty) {
      return ResolvedRoute(
        target: target,
        path: route.path,
        fragment: fragment,
        name: route.name,
        groupName: route.groupName,
        viewIndex: route.viewIndex,
        history: route.history,
        presenter: route.presenter,
        transition: route.transition,
        params: {...params},
        ancestors: route.ancestors,
      );
    }
    throw Exception(
      'Resolved route does not define a fragment: '
      'path=${route.path}, name=${route.name}, groupName=${route.groupName}',
    );
  }

  static void _schedulePendingRouteProcessing() {
    if (_pendingRouteScheduled) return;
    _pendingRouteScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingRouteScheduled = false;

      // On first run, resolve the browser URL
      if (_pendingRoute == null && !_initialRouteProcessed) {
        _initialRouteProcessed = true;
        final resolved = resolve(WebUrlSync.currentPath) ?? resolve('/');
        if (resolved == null) {
          WebUrlSync.replaceUrl('/');
          return;
        }
        _pendingRoute = _PendingRoute(
          resolved: resolved,
          urlUpdate: resolved.target != WebUrlSync.currentPath
              ? _UrlUpdate.replace
              : _UrlUpdate.none,
          remainingAncestors: [...resolved.ancestors],
        );
      }

      _processPendingRoute();
    });
  }

  /// Walks the ancestor chain of the pending route, activating
  /// each level whose callback is registered. Stops at the first
  /// unregistered callback and waits — the next
  /// [registerRouteCallback] call resumes the cascade.
  static void _processPendingRoute() {
    final pending = _pendingRoute;
    if (pending == null) return;

    // Activate ancestors top-down
    while (pending.remainingAncestors.isNotEmpty) {
      final ancestor = pending.remainingAncestors.first;
      final callback = _callbacks[ancestor.groupName];
      if (callback == null) return; // wait for registration
      callback(ancestor.viewIndex, ancestor.name, pending.resolved.params);
      pending.remainingAncestors.removeAt(0);
    }

    // All ancestors processed — check final route's group
    final group = pending.resolved.groupName;
    if (group != null && !_callbacks.containsKey(group)) {
      return; // wait for callback registration
    }

    // Navigate to final destination
    final resolved = pending.resolved;
    final urlUpdate = pending.urlUpdate;
    _pendingRoute = null;
    _navigateToRoute(
      resolved,
      dependencies: pending.dependencies,
      action: pending.action,
      params: pending.params,
      urlUpdate: urlUpdate,
    );
  }

  static void _dialogPresenter(
    ResolvedRoute route,
    Dependencies deps,
    Map<String, dynamic> params,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    showDialog(
      context: context,
      builder: (_) => XWidget.inflateFragment(route.fragment, deps, params: params) as Widget,
    );
  }

  static void _bottomSheetPresenter(
    ResolvedRoute route,
    Dependencies deps,
    Map<String, dynamic> params,
  ) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => XWidget.inflateFragment(route.fragment, deps, params: params) as Widget,
    );
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
  static List<_Route> _parseRouteGroup(
    XmlElement element, {
    String? parentGroupName,
    String? parentGroupPath,
    bool parentGroupHistory = true,
    String? parentGroupPresenter,
    String? parentGroupTransition,
    int? parentViewIndex,
    List<RouteActivation> parentAncestors = const [],
  }) {
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

    final isNested = parentGroupName != null;
    final groupFragment = element.getAttribute('fragment');

    final groupHistory = tryParseBool(element.getAttribute('history')) ?? parentGroupHistory;
    final groupPresenter = element.getAttribute('presenter') ?? parentGroupPresenter;
    final groupTransition = element.getAttribute('transition') ?? parentGroupTransition;

    // Compute full path for nested groups (parent prefix + group path)
    final fullGroupPath = isNested && parentGroupPath != null && groupPath != null
        ? '$parentGroupPath$groupPath'.replaceAll(RegExp(r'/+'), '/')
        : groupPath;

    // Build ancestor chain for children of this group
    final childAncestors = isNested
        ? [
            ...parentAncestors,
            RouteActivation(
              groupName: parentGroupName,
              viewIndex: parentViewIndex!,
              name: groupName,
              path: fullGroupPath,
              fragment: groupFragment,
              transition: groupTransition,
            ),
          ]
        : parentAncestors;

    var index = 0;
    final routes = <_Route>[];
    for (final child in element.childElements) {
      switch (child.name.local) {
        case 'route':
          final route = _parseRoute(
            child,
            groupName: groupName,
            groupPath: fullGroupPath,
            groupHistory: groupHistory,
            groupPresenter: groupPresenter,
            groupTransition: groupTransition,
            viewIndex: index,
            ancestors: childAncestors,
          );
          routes.add(route);
          index++;
        case 'routeGroup':
          final nestedRoutes = _parseRouteGroup(
            child,
            parentGroupName: groupName,
            parentGroupPath: fullGroupPath,
            parentGroupHistory: groupHistory,
            parentGroupPresenter: groupPresenter,
            parentGroupTransition: groupTransition,
            parentViewIndex: index,
            parentAncestors: childAncestors,
          );
          routes.addAll(nestedRoutes);
          index++;
      }
    }

    // Set aliases on the group's default child route
    final defaultChild = routes.where((r) => r.groupName == groupName).firstOrNull;
    if (defaultChild != null) {
      defaultChild.aliases.add(groupName);
      if (!isNested && groupPath != null && groupPath.isNotEmpty) {
        defaultChild.aliases.add(groupPath);
      } else if (isNested && fullGroupPath != null) {
        defaultChild.aliases.add(fullGroupPath);
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
    String? groupPresenter,
    String? groupTransition,
    int? viewIndex,
    List<RouteActivation> ancestors = const [],
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

    // fragment or redirect is required
    final fragment = element.getAttribute('fragment');
    final redirect = element.getAttribute('redirect');
    final hasFragment = fragment != null && fragment.isNotEmpty;
    final hasRedirect = redirect != null && redirect.isNotEmpty;
    if (!hasFragment && !hasRedirect) {
      throw Exception("route '$path' requires either a 'fragment' or 'redirect' attribute");
    }
    if (hasFragment && hasRedirect) {
      throw Exception("route '$path' cannot specify both 'fragment' and 'redirect' attributes");
    }
    if (hasRedirect) {
      if (!redirect.startsWith('/')) {
        throw Exception("route 'redirect' must begin with a slash (/)");
      }
      if (redirect.contains(RegExp(r'//')) || (redirect.length > 1 && redirect.endsWith('/'))) {
        throw Exception("route redirect '$path' contains extra or trailing slashes");
      }
    }

    final name = element.getAttribute('name');
    final fullPath = (groupPath != null) ? '$groupPath$path'.replaceAll(RegExp(r'/+'), '/') : path;
    final fullName = (groupName != null && name != null) ? '$groupName:$name' : name;
    final history = tryParseBool(element.getAttribute('history')) ?? groupHistory;
    final presenter = element.getAttribute('presenter') ?? groupPresenter;
    final transition = element.getAttribute('transition') ?? groupTransition;

    return _Route(
      name: fullName,
      path: fullPath,
      redirect: redirect,
      fragment: fragment,
      groupName: groupName,
      groupPath: groupPath,
      history: history,
      presenter: presenter,
      transition: transition,
      viewIndex: viewIndex,
      ancestors: ancestors,
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
  final String? redirect;
  final String? fragment;
  final String? groupName;
  final String? groupPath;
  final bool history;
  final String? presenter;
  final String? transition;
  final int? viewIndex;
  final List<String> aliases = [];
  final List<RouteActivation> ancestors;

  _Route({
    this.name,
    required this.path,
    this.fragment,
    this.redirect,
    this.groupName,
    this.groupPath,
    this.history = true,
    this.presenter,
    this.transition,
    this.viewIndex,
    this.ancestors = const [],
  });
}

/// Compiled pattern for a parameterized route.
class _RoutePattern {
  final _Route route;
  final RegExp regExp;
  final List<String> paramNames;

  const _RoutePattern({required this.route, required this.regExp, required this.paramNames});
}

/// Tracks an in-progress navigation through a nested route
/// chain. Ancestors are consumed as each level activates.
class _PendingRoute {
  final ResolvedRoute resolved;
  final Dependencies? dependencies;
  final NavigatorAction action;
  final Map<String, dynamic>? params;
  final _UrlUpdate urlUpdate;
  final List<RouteActivation> remainingAncestors;

  _PendingRoute({
    required this.resolved,
    this.dependencies,
    this.action = NavigatorAction.push,
    this.params,
    this.urlUpdate = _UrlUpdate.push,
    required this.remainingAncestors,
  });
}

class _TargetUri {
  static final _paramPattern = RegExp(r':(\w+)');
  static final _multiSlash = RegExp(r'/+');

  final Uri _uri;
  final String path;

  _TargetUri._(this._uri, this.path);

  factory _TargetUri.parse(String target) {
    // Collapse repeated slashes in path-style targets BEFORE Uri.parse —
    // a leading "//" would otherwise be read as a URI authority (host) and
    // swallow the first path segment. Only the path portion is collapsed;
    // query values (e.g. ?next=https://...) must survive untouched. Full
    // URLs keep their scheme's "//" and are normalized post-parse below.
    if (target.startsWith('/')) {
      final queryStart = target.indexOf('?');
      target = queryStart == -1
          ? target.replaceAll(_multiSlash, '/')
          : target.substring(0, queryStart).replaceAll(_multiSlash, '/') +
                target.substring(queryStart);
    }
    final uri = Uri.parse(target);
    final normalizedPath = uri.path.replaceAll(_multiSlash, '/');
    return _TargetUri._(uri, normalizedPath);
  }

  String get query => _uri.query;
  bool get hasQuery => _uri.hasQuery;
  Map<String, String> get queryParameters => _uri.queryParameters;

  String buildTargetPath(String destinationPath, [_RoutePattern? matchedPattern]) {
    if (matchedPattern == null) {
      // No source pattern means no parameter values exist to substitute —
      // any placeholder left in the destination is unresolvable. Without
      // this guard, ":param" passes through literally and can "match" the
      // destination's own pattern with the placeholder as the value.
      final unresolved = _paramPattern.firstMatch(destinationPath);
      if (unresolved != null) {
        throw Exception(
          'Unresolved path parameter ":${unresolved.group(1)}" in '
          '"$destinationPath". The source route is not parameterized.',
        );
      }
      var concretePath = destinationPath.replaceAll(_multiSlash, '/');
      return hasQuery ? '$concretePath?$query' : concretePath;
    }

    final match = matchedPattern.regExp.firstMatch(path);
    final pathParams = <String, String>{};
    if (match != null) {
      for (var i = 0; i < matchedPattern.paramNames.length; i++) {
        pathParams[matchedPattern.paramNames[i]] = match.group(i + 1)!;
      }
    }

    var concretePath = destinationPath
        .replaceAllMapped(_paramPattern, (m) {
          final name = m.group(1)!;
          final value = pathParams[name];
          if (value == null) {
            throw Exception(
              'Unresolved path parameter ":$name" in "$destinationPath". '
              'Source pattern "${matchedPattern.route.path}" does not define ":$name".',
            );
          }
          return value;
        })
        .replaceAll(_multiSlash, '/');

    return hasQuery ? '$concretePath?$query' : concretePath;
  }
}

enum _UrlUpdate { none, push, replace }
