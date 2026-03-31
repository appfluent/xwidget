import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import '../utils/hash.dart';
import '../utils/platform/platform_utils.dart' as platform;
import '../utils/version.dart';
import 'analytics_event.dart';
import 'analytics_store.dart';

final _log = Logger('Analytics');

/// Captures, aggregates, persists, and flushes analytics events to the
/// XWidget Cloud analytics server.
///
/// Events are aggregated in memory, periodically persisted to local
/// storage, and flushed to the server on a longer interval. On app
/// pause or close, in-memory events are persisted and a flush is
/// attempted.
///
/// Events are split by type (render, download, error) at persist time
/// into separate files. Each type is sent and deleted independently
/// during flush — a failed download send does not block render or
/// error cleanup.
class Analytics with WidgetsBindingObserver {
  static Analytics? _instance;

  static Analytics get instance {
    if (_instance == null) {
      throw StateError(
        'Analytics has not been initialized. '
        'Call Analytics.initialize() first.',
      );
    }
    return _instance!;
  }

  static const _maxDistinctErrors = 50;
  static const _defaultPersistInterval = Duration(seconds: 10);
  static const _defaultFlushInterval = Duration(minutes: 15);
  static const _defaultMaxFileAge = Duration(hours: 72);
  static const _defaultSessionTimeout = Duration(minutes: 15);
  static const _analyticsBaseUrl = String.fromEnvironment(
    'XWIDGET_ANALYTICS_URL',
    defaultValue: 'https://analytics.xwidget.dev',
  );

  final String _projectKey;
  final String _channel;
  final String _versionNumber;
  final String _versionMetadata;
  final String _platform;
  final String _locale;
  final Duration _persistInterval;
  final Duration _flushInterval;
  final Duration _maxFileAge;
  final Duration _sessionTimeout;

  final _memoryBuffer = <String, AnalyticsEvent>{};
  late final AnalyticsStore _store;
  Timer? _persistTimer;
  Timer? _flushTimer;
  bool _isFlushing = false;
  Session _session = Session();

  Analytics._({
    required String projectKey,
    required String channel,
    required String versionNumber,
    required String versionMetadata,
    required String platform,
    required String locale,
    Duration persistInterval = _defaultPersistInterval,
    Duration flushInterval = _defaultFlushInterval,
    Duration maxFileAge = _defaultMaxFileAge,
    Duration sessionTimeout = _defaultSessionTimeout,
  }) : _projectKey = projectKey,
       _channel = channel,
       _versionNumber = versionNumber,
       _versionMetadata = versionMetadata,
       _platform = platform,
       _locale = locale,
       _persistInterval = persistInterval,
       _flushInterval = flushInterval,
       _maxFileAge = maxFileAge,
       _sessionTimeout = sessionTimeout {
    _store = AnalyticsStore();
  }

  static bool get isInitialized => _instance != null;

  /// Initializes the Analytics singleton.
  ///
  /// Must be called before any events are tracked. Typically called
  /// from [XWidget.initialize].
  ///
  /// [projectKey] is sent as the X-API-Key header for authentication.
  /// [channel] and [version] are attached to every event.
  /// [version] is split into version number and metadata at the '+'
  /// delimiter.
  static Future<void> initialize({
    required String projectKey,
    required String channel,
    required String version,
    Duration persistInterval = _defaultPersistInterval,
    Duration flushInterval = _defaultFlushInterval,
    Duration maxFileAge = _defaultMaxFileAge,
  }) async {
    if (_instance != null) {
      _log.warning('Analytics already initialized, ignoring');
      return;
    }

    // parse version
    final ver = Version.parse(version);

    // Detect platform
    final plat = _detectPlatform();

    // Get locale country code
    final locale = ui.PlatformDispatcher.instance.locale.countryCode ?? '';

    _instance = Analytics._(
      projectKey: projectKey,
      channel: channel,
      versionNumber: ver.number,
      versionMetadata: ver.metadata ?? '',
      platform: plat,
      locale: locale,
      persistInterval: persistInterval,
      flushInterval: flushInterval,
      maxFileAge: maxFileAge,
    );

    _instance!._start();
    _log.info(
      'Analytics initialized: channel=$channel, version=$version, '
      'platform=$plat, locale=$locale',
    );
  }

  /// Shuts down the Analytics singleton, flushing any remaining events.
  static Future<void> shutdown() async {
    final instance = _instance;
    if (instance == null) return;
    await instance._stop();
    _instance = null;
    _log.info('Analytics shut down');
  }

  /// Detects the current platform.
  ///
  /// Uses [kIsWeb] for web detection and [Platform.operatingSystem] from
  /// dart:io for all other platforms. We use Platform.operatingSystem
  /// instead of defaultTargetPlatform because it returns the actual OS
  /// the code is running on, not the target platform — which can differ
  /// when debugging (e.g., Chrome targeting Android would report
  /// 'android' with defaultTargetPlatform).
  static String _detectPlatform() {
    return platform.getPlatformName();
  }

  // ---------------------------------------------------------------------------
  // Public API — tracking events
  // ---------------------------------------------------------------------------

  /// Tracks a fragment render event.
  ///
  /// Safe to call even if Analytics has not been initialized — silently
  /// no-ops if [projectKey] was not provided.
  static void trackRender({required String fragmentName, bool isError = false}) {
    final inst = _instance;
    if (inst == null) return;

    final now = DateTime.now().toUtc();
    final event = RenderEvent(
      channel: inst._channel,
      versionNumber: inst._versionNumber,
      versionMetadata: inst._versionMetadata,
      platform: inst._platform,
      locale: inst._locale,
      fragmentName: fragmentName,
      renderCount: isError ? 0 : 1,
      errorCount: isError ? 1 : 0,
      timestamp: now,
    );
    inst._addEvent(event);
  }

  /// Tracks a bundle download event.
  ///
  /// [isCacheHit] indicates whether the bundle was served from cache
  /// (304) or downloaded fresh (200).
  ///
  /// Safe to call even if Analytics has not been initialized — silently
  /// no-ops if [projectKey] was not provided.
  static void trackDownload({bool isCacheHit = false, bool isError = false}) {
    final inst = _instance;
    if (inst == null) return;

    final now = DateTime.now().toUtc();
    final event = DownloadEvent(
      channel: inst._channel,
      versionNumber: inst._versionNumber,
      versionMetadata: inst._versionMetadata,
      platform: inst._platform,
      locale: inst._locale,
      cacheCount: isCacheHit ? 1 : 0,
      downloadCount: (!isCacheHit && !isError) ? 1 : 0,
      errorCount: isError ? 1 : 0,
      timestamp: now,
    );
    inst._addEvent(event);
  }

  /// Tracks an error with detail for the error log table.
  ///
  /// The [error] message is truncated to 512 characters. Unique error
  /// messages are capped at [_maxDistinctErrors] per persist cycle to
  /// prevent runaway error storms from flooding storage.
  ///
  /// Safe to call even if Analytics has not been initialized — silently
  /// no-ops if [projectKey] was not provided.
  static void trackError({required Object error, String? fragmentName, bool isDownload = false}) {
    final inst = _instance;
    if (inst == null) return;

    // Track error count on the appropriate aggregate table
    if (isDownload) {
      trackDownload(isError: true);
    } else if (fragmentName != null && fragmentName.isNotEmpty) {
      trackRender(fragmentName: fragmentName, isError: true);
    }

    // Track actual error event
    final now = DateTime.now().toUtc();
    inst._addEvent(
      ErrorEvent(
        channel: inst._channel,
        versionNumber: inst._versionNumber,
        versionMetadata: inst._versionMetadata,
        platform: inst._platform,
        locale: inst._locale,
        fragmentName: fragmentName ?? '',
        errorMessage: error.toString(),
        errorCount: 1,
        timestamp: now,
      ),
    );
  }

  /// Tracks a navigation event for the current page.
  ///
  /// Records the user's navigation to [pageName] for flow analysis in
  /// XWidget Cloud analytics. Events include a session identifier and
  /// sequence number to reconstruct user journeys across fragments.
  ///
  /// Sessions are managed automatically. If the time since the last
  /// recorded activity exceeds the session timeout, a new session is
  /// started with a fresh ID and sequence counter. Otherwise, the
  /// existing session continues and the sequence number increments.
  ///
  /// Navigation events are batched internally via [_addEvent] and
  /// flushed periodically to the analytics endpoint.
  ///
  /// No-op if the Analytics instance has not been initialized.
  ///
  /// - [pageName]: The name of the page or fragment being navigated to.
  ///   Leading and trailing whitespace is trimmed.
  static void trackNavigation({required String pageName}) {
    final inst = _instance;
    if (inst == null) return;

    final now = DateTime.now().toUtc();

    // update session tracker
    if (now.difference(inst._session.lastActivity) > inst._sessionTimeout) {
      inst._session = Session();
    } else {
      inst._session.lastActivity = now;
    }

    // record navigation event if pageName present
    final sessionId = inst._session.id;
    final sessionSeq = ++inst._session.sequence;
    final event = NavigationEvent(
      channel: inst._channel,
      versionNumber: inst._versionNumber,
      versionMetadata: inst._versionMetadata,
      platform: inst._platform,
      locale: inst._locale,
      pageName: pageName.trim(),
      sessionId: sessionId,
      sessionSeq: sessionSeq,
      timestamp: now,
    );
    inst._addEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Internal — event aggregation
  // ---------------------------------------------------------------------------

  void _addEvent(AnalyticsEvent event) {
    final key = event.aggregationKey;
    final existing = _memoryBuffer[key];
    if (existing != null) {
      existing.mergeFrom(event);
    } else {
      // Cap distinct error events to prevent runaway error storms
      if (event is ErrorEvent) {
        final errorCount = _memoryBuffer.keys.where((k) => k.startsWith('error|')).length;
        if (errorCount >= _maxDistinctErrors) return;
      }
      _memoryBuffer[key] = event;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal — lifecycle and timers
  // ---------------------------------------------------------------------------

  void _start() {
    WidgetsBinding.instance.addObserver(this);
    _startTimers();

    // Flush any unsent files from previous sessions
    _flushToServer();
  }

  Future<void> _stop() async {
    _cancelTimers();
    WidgetsBinding.instance.removeObserver(this);
    await _persistToStorage();
    await _flushToServer();
  }

  void _startTimers() {
    _persistTimer = Timer.periodic(_persistInterval, (_) {
      _persistToStorage();
    });
    _flushTimer = Timer.periodic(_flushInterval, (_) {
      _flushToServer();
    });
  }

  void _cancelTimers() {
    _persistTimer?.cancel();
    _persistTimer = null;
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  /// This is a fire-and-forget callback so there is no point in awaiting
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _log.fine('App lifecycle: $state — persisting and flushing');
      _flushToServer();
    }
  }

  // ---------------------------------------------------------------------------
  // Internal — persist (memory → storage)
  // ---------------------------------------------------------------------------

  Future<void> _persistToStorage() async {
    if (_memoryBuffer.isEmpty) return;

    // Snapshot and clear the buffer before the async write so that
    // new events arriving during the await go into a fresh buffer
    // instead of being lost when we clear after the write completes.
    final events = _memoryBuffer.values.toList();
    _memoryBuffer.clear();

    try {
      await _store.writeEvents(events);
      _log.fine('Persisted ${events.length} aggregated events to storage');
    } catch (e, stack) {
      _log.warning('Failed to persist events to storage: $e $stack');
      // Put events back so they aren't lost — they'll be retried on
      // the next persist cycle. This merges cleanly with any new
      // events that arrived during the failed write.
      for (final event in events) {
        _addEvent(event);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Internal — flush (storage → server)
  // ---------------------------------------------------------------------------

  Future<void> _flushToServer() async {
    if (_isFlushing) return;
    _isFlushing = true;

    try {
      // First, persist any in-memory events
      await _persistToStorage();

      // Rotate current files so they become eligible for sending
      await _store.rotateFiles();

      // Flush each event type independently
      for (final eventType in EventType.values) {
        await _flushEventType(eventType);
      }
    } catch (e) {
      _log.warning('Flush failed: $e');
    } finally {
      _isFlushing = false;
    }
  }

  /// Flushes all unsent files for a single event type.
  ///
  /// Reads all unsent files, removes stale ones, re-aggregates across
  /// files, sends to server, and deletes files on success. Each event
  /// type is fully independent — a failure here does not affect other
  /// event types.
  Future<void> _flushEventType(EventType eventType) async {
    final unsentFiles = await _store.readUnsent(eventType);
    if (unsentFiles.isEmpty) return;

    // Remove stale files that exceed maxFileAge
    final now = DateTime.now().millisecondsSinceEpoch;
    final staleFileIds = <String>[];
    for (final fileId in unsentFiles.keys) {
      final fileTimestamp = int.tryParse(fileId);
      if (fileTimestamp != null && (now - fileTimestamp) > _maxFileAge.inMilliseconds) {
        staleFileIds.add(fileId);
      }
    }
    for (final fileId in staleFileIds) {
      unsentFiles.remove(fileId);
      await _store.deleteFile(eventType, fileId);
      _log.info('Deleted stale ${eventType.name} file: $fileId');
    }

    if (unsentFiles.isEmpty) return;

    // Aggregate all events across files to minimize payload
    final aggregated = <String, AnalyticsEvent>{};
    for (final events in unsentFiles.values) {
      for (final event in events) {
        final key = event.aggregationKey;
        final existing = aggregated[key];
        if (existing != null) {
          existing.mergeFrom(event);
        } else {
          // Create a copy via round-trip to avoid mutating stored events
          aggregated[key] = AnalyticsEvent.fromJson(eventType, event.toJson());
        }
      }
    }

    // Send to server
    final endpoint = eventType.endpoint;
    final success = await _sendEvents(endpoint, aggregated.values.toList());
    if (success) {
      for (final fileId in unsentFiles.keys) {
        await _store.deleteFile(eventType, fileId);
      }
      _log.info('Flushed ${aggregated.length} ${eventType.name} events');
    } else {
      _log.warning('Failed to flush ${eventType.name} events');
    }
  }

  Future<bool> _sendEvents(String path, List<AnalyticsEvent> events) async {
    if (events.isEmpty) return true;

    try {
      final url = '$_analyticsBaseUrl$path';
      final body = jsonEncode({
        'events': events.map((e) {
          final json = e.toJson();
          json.remove('type'); // Server doesn't need the type field
          return json;
        }).toList(),
      });

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', 'X-API-Key': _projectKey},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _log.fine('Sent ${events.length} events to $path');
        return true;
      } else {
        _log.warning('Server returned ${response.statusCode} for $path');
        return false;
      }
    } catch (e) {
      _log.warning('Failed to send events to $path: $e');
      return false;
    }
  }
}

/// A [NavigatorObserver] that automatically tracks navigation events
/// for XWidget Cloud analytics.
///
/// Listens to push, pop, and replace navigation actions and forwards
/// the route name to [Analytics.trackNavigation] for session-based
/// flow analysis. The route name is taken from [RouteSettings.name];
/// if unavailable, `'<unknown>'` is recorded.
///
/// Add this observer to your app's navigator to enable automatic
/// navigation tracking without manual instrumentation:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [AnalyticsNavigatorObserver()],
///   // ...
/// )
/// ```
///
/// On pop events, the *previous* route is tracked since it becomes
/// the visible page after the current route is removed.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    _track(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _track(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _track(newRoute);
  }

  void _track(Route? route) {
    final name = route?.settings.name;
    Analytics.trackNavigation(pageName: name ?? '<unknown>');
  }
}

class Session {
  final String id = nanoid(32);
  int sequence = 0;
  DateTime lastActivity = DateTime.now();
}
