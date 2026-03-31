import 'dart:convert';

/// Event type identifiers used in file naming and storage keys.
enum EventType {
  render('renders', '/ingest/renders'),
  download('downloads', '/ingest/downloads'),
  navigation('navigation', '/ingest/navigation'),
  error('errors', '/ingest/errors');

  final String storagePrefix;
  final String endpoint;

  const EventType(this.storagePrefix, this.endpoint);

  static EventType eventTypeFor(AnalyticsEvent event) {
    if (event is RenderEvent) return EventType.render;
    if (event is DownloadEvent) return EventType.download;
    if (event is NavigationEvent) return EventType.navigation;
    if (event is ErrorEvent) return EventType.error;
    throw ArgumentError('Unknown event type: ${event.runtimeType}');
  }
}

/// Base class for analytics events with shared dimensions.
abstract class AnalyticsEvent {
  final String channel;
  final String versionNumber;
  final String versionMetadata;
  final String platform;
  final String locale;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.channel,
    required this.versionNumber,
    required this.versionMetadata,
    required this.platform,
    required this.locale,
    required this.timestamp,
  });

  /// Returns a key that uniquely identifies the dimension combination
  /// for aggregation purposes.
  String get aggregationKey;

  String get eventDate => _formatDate(timestamp);

  int get eventHour => timestamp.hour;

  /// Merges the counts from [other] into this event.
  void mergeFrom(AnalyticsEvent other);

  /// Serializes this event to a JSON-compatible map.
  Map<String, dynamic> toJson();

  /// Deserializes an event from a JSON map.
  factory AnalyticsEvent.fromJson(EventType eventType, Map<String, dynamic> json) {
    switch (eventType) {
      case EventType.render:
        return RenderEvent.fromJson(json);
      case EventType.download:
        return DownloadEvent.fromJson(json);
      case EventType.navigation:
        return NavigationEvent.fromJson(json);
      case EventType.error:
        return ErrorEvent.fromJson(json);
    }
  }

  /// Serializes this event to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  static DateTime toDateTime(String date, int hour) {
    return DateTime.parse('$date ${hour.toString().padLeft(2, '0')}:00:00');
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

// =============================================================================
// RenderEvent
// =============================================================================

class RenderEvent extends AnalyticsEvent {
  final String fragmentName;
  int renderCount;
  int errorCount;

  RenderEvent({
    required super.channel,
    required super.versionNumber,
    required super.versionMetadata,
    required super.platform,
    required super.locale,
    required this.fragmentName,
    required this.renderCount,
    required this.errorCount,
    required super.timestamp,
  });

  @override
  String get aggregationKey =>
      'render|$channel|$versionNumber|$versionMetadata|$platform|'
      '$locale|$fragmentName|$eventDate|$eventHour';

  @override
  void mergeFrom(AnalyticsEvent other) {
    if (other is RenderEvent) {
      renderCount += other.renderCount;
      errorCount += other.errorCount;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': EventType.render.name,
    'channel': channel,
    'version_number': versionNumber,
    'version_metadata': versionMetadata,
    'platform': platform,
    'locale': locale,
    'fragment_name': fragmentName,
    'render_count': renderCount,
    'error_count': errorCount,
    'event_date': eventDate,
    'event_hour': eventHour,
  };

  factory RenderEvent.fromJson(Map<String, dynamic> json) => RenderEvent(
    channel: json['channel'] as String,
    versionNumber: json['version_number'] as String,
    versionMetadata: json['version_metadata'] as String? ?? '',
    platform: json['platform'] as String,
    locale: json['locale'] as String,
    fragmentName: json['fragment_name'] as String,
    renderCount: json['render_count'] as int,
    errorCount: json['error_count'] as int,
    timestamp: AnalyticsEvent.toDateTime(json['event_date'] as String, json['event_hour'] as int),
  );
}

// =============================================================================
// DownloadEvent
// =============================================================================

class DownloadEvent extends AnalyticsEvent {
  int cacheCount;
  int downloadCount;
  int errorCount;

  DownloadEvent({
    required super.channel,
    required super.versionNumber,
    required super.versionMetadata,
    required super.platform,
    required super.locale,
    required this.cacheCount,
    required this.downloadCount,
    required this.errorCount,
    required super.timestamp,
  });

  @override
  String get aggregationKey =>
      'download|$channel|$versionNumber|$versionMetadata|$platform|'
      '$locale|$eventDate|$eventHour';

  @override
  void mergeFrom(AnalyticsEvent other) {
    if (other is DownloadEvent) {
      cacheCount += other.cacheCount;
      downloadCount += other.downloadCount;
      errorCount += other.errorCount;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': EventType.download.name,
    'channel': channel,
    'version_number': versionNumber,
    'version_metadata': versionMetadata,
    'platform': platform,
    'locale': locale,
    'cache_count': cacheCount,
    'download_count': downloadCount,
    'error_count': errorCount,
    'event_date': eventDate,
    'event_hour': eventHour,
  };

  factory DownloadEvent.fromJson(Map<String, dynamic> json) => DownloadEvent(
    channel: json['channel'] as String,
    versionNumber: json['version_number'] as String,
    versionMetadata: json['version_metadata'] as String? ?? '',
    platform: json['platform'] as String,
    locale: json['locale'] as String,
    cacheCount: json['cache_count'] as int? ?? 0,
    downloadCount: json['download_count'] as int,
    errorCount: json['error_count'] as int,
    timestamp: AnalyticsEvent.toDateTime(json['event_date'] as String, json['event_hour'] as int),
  );
}

// =============================================================================
// NavigationEvent
// =============================================================================

class NavigationEvent extends AnalyticsEvent {
  final String pageName;
  final String sessionId;
  final int sessionSeq;

  NavigationEvent({
    required super.channel,
    required super.versionNumber,
    required super.versionMetadata,
    required super.platform,
    required super.locale,
    required this.pageName,
    required this.sessionId,
    required this.sessionSeq,
    required super.timestamp,
  });

  @override
  String get aggregationKey =>
      'navigation|$channel|$versionNumber|$versionMetadata|$platform|'
      '$locale|$pageName|$sessionId|$sessionSeq|$timestamp';

  @override
  void mergeFrom(AnalyticsEvent other) {}

  @override
  Map<String, dynamic> toJson() => {
    'type': EventType.navigation.name,
    'channel': channel,
    'version_number': versionNumber,
    'version_metadata': versionMetadata,
    'platform': platform,
    'locale': locale,
    'page_name': pageName,
    'session_id': sessionId,
    'session_seq': sessionSeq,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory NavigationEvent.fromJson(Map<String, dynamic> json) => NavigationEvent(
    channel: json['channel'] as String,
    versionNumber: json['version_number'] as String,
    versionMetadata: json['version_metadata'] as String? ?? '',
    platform: json['platform'] as String,
    locale: json['locale'] as String,
    pageName: json['page_name'] as String,
    sessionId: json['session_id'] as String,
    sessionSeq: json['session_seq'] as int,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int, isUtc: true),
  );
}

// =============================================================================
// ErrorEvent
// =============================================================================

class ErrorEvent extends AnalyticsEvent {
  static const maxMessageLength = 512;

  final String fragmentName;
  final String errorMessage;
  int errorCount;

  ErrorEvent({
    required super.channel,
    required super.versionNumber,
    required super.versionMetadata,
    required super.platform,
    required super.locale,
    required this.fragmentName,
    required String errorMessage,
    required this.errorCount,
    required super.timestamp,
  }) : errorMessage = errorMessage.length > maxMessageLength
           ? errorMessage.substring(0, maxMessageLength)
           : errorMessage;

  @override
  String get aggregationKey =>
      'error|$channel|$versionNumber|$versionMetadata|$platform|'
      '$locale|$fragmentName|$errorMessage|$eventDate|$eventHour';

  @override
  void mergeFrom(AnalyticsEvent other) {
    if (other is ErrorEvent) {
      errorCount += other.errorCount;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': EventType.error.name,
    'channel': channel,
    'version_number': versionNumber,
    'version_metadata': versionMetadata,
    'platform': platform,
    'locale': locale,
    'fragment_name': fragmentName,
    'error_message': errorMessage,
    'error_count': errorCount,
    'event_date': eventDate,
    'event_hour': eventHour,
  };

  factory ErrorEvent.fromJson(Map<String, dynamic> json) => ErrorEvent(
    channel: json['channel'] as String,
    versionNumber: json['version_number'] as String,
    versionMetadata: json['version_metadata'] as String? ?? '',
    platform: json['platform'] as String,
    locale: json['locale'] as String,
    fragmentName: json['fragment_name'] as String,
    errorMessage: json['error_message'] as String,
    errorCount: json['error_count'] as int,
    timestamp: AnalyticsEvent.toDateTime(json['event_date'] as String, json['event_hour'] as int),
  );
}
