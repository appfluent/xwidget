import 'dart:js_interop';
import 'dart:ui_web';

import 'xrouter.dart';

@JS('window.location.pathname')
external JSString get _pathname;

@JS('window.location.search')
external JSString get _search;

@JS('window.history.pushState')
external void _pushState(JSAny? state, JSString title, JSString url);

@JS('window.history.replaceState')
external void _replaceState(JSAny? state, JSString title, JSString url);

@JS('window.history.back')
external void _historyBack();

@JS('window.addEventListener')
external void _addEventListener(JSString type, JSFunction callback);

@JS('window.removeEventListener')
external void _removeEventListener(JSString type, JSFunction callback);

/// Connects [XRouter] to the browser's History API.
///
/// Call [WebUrlSync.enable] during app startup on web platforms
/// to activate URL synchronization. This wires up three behaviors:
///
/// 1. Reads the current URL on startup to determine the initial
///    route.
/// 2. Updates the URL when [XRouter.goTo] navigates to a new
///    route.
/// 3. Listens for browser back/forward button presses and
///    notifies the router.
///
/// Uses `dart:js_interop` directly — no external package
/// dependencies.
class WebUrlSync {
  WebUrlSync._();

  static JSFunction? _popStateHandler;
  static bool _enabled = false;

  /// The current URL path from the browser's address bar.
  static String get currentPath => _pathname.toDart + _search.toDart;

  /// Activates URL synchronization between [XRouter] and the
  /// browser.
  ///
  /// Sets [XRouter.onUrlChanged] to push URL changes to the
  /// browser history, and registers a `popstate` listener to
  /// handle back/forward navigation.
  static void enable() {
    if (_enabled) return;

    if (urlStrategy != null) {
      throw StateError(
        'XRouter grouped route navigation (PageView, TabBarView, IndexedStack) '
        'requires browser history management, which conflicts with Flutter\'s '
        'built-in URL strategy. Call setUrlStrategy(null) before runApp() in '
        'main.dart to disable Flutter\'s URL handling.',
      );
    }

    _enabled = true;
    _popStateHandler = _onPopState.toJS;
    _addEventListener('popstate'.toJS, _popStateHandler!);
  }

  /// Deactivates URL synchronization and removes the popstate
  /// listener.
  static void disable() {
    if (!_enabled) return;

    _enabled = false;
    if (_popStateHandler != null) {
      _removeEventListener('popstate'.toJS, _popStateHandler!);
      _popStateHandler = null;
    }
  }

  /// Updates the browser URL without triggering a page reload.
  static void pushUrl(String path) {
    if (path == currentPath) return;
    _pushState(null, ''.toJS, path.toJS);
  }

  /// Replaces the current browser URL without adding a history
  /// entry. Used for redirects where the original URL should not
  /// appear in the back stack.
  static void replaceUrl(String path) {
    if (path == currentPath) return;
    _replaceState(null, ''.toJS, path.toJS);
  }

  /// Handles browser back/forward button presses.
  ///
  /// Reads the new URL path, resolves the route, and navigates
  /// to it. If the route belongs to an inactive group, skips
  /// the entry by calling back again.
  static void _onPopState(JSAny? event) {
    final path = currentPath;
    final resolved = XRouter.resolve(path);

    if (resolved == null) return;

    // Skip entries for inactive groups
    if (resolved.groupName != null) {
      final hasView = XRouter.hasRegisteredView(resolved.groupName!);
      if (!hasView) {
        _historyBack();
        return;
      }
    }

    // Navigate without updating the URL (the browser already did)
    XRouter.goTo(path);
  }
}
