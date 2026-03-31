import 'analytics_event.dart';
import 'analytics_store_stub.dart'
    if (dart.library.io) 'analytics_store_io.dart'
    if (dart.library.js_interop) 'analytics_store_web.dart';

/// Persistent storage for analytics events.
///
/// Events are split by type and written to separate files/entries on
/// each persist cycle. On flush, each type's files are sent and
/// deleted independently — a failed download send does not block
/// render or error file cleanup.
abstract class AnalyticsStore {
  factory AnalyticsStore() => createAnalyticsStore();

  /// Writes a batch of aggregated events to storage, splitting them
  /// into separate files/entries by event type.
  Future<void> writeEvents(List<AnalyticsEvent> events);

  /// Closes the current set of files and starts new ones.
  Future<void> rotateFiles();

  /// Returns all events from unsent files for the given [eventType].
  /// Keys are file IDs, values are the events in that file.
  Future<Map<String, List<AnalyticsEvent>>> readUnsent(EventType eventType);

  /// Deletes a successfully flushed file by its [eventType] and [fileId].
  Future<void> deleteFile(EventType eventType, String fileId);

  /// Deletes all stored event files.
  Future<void> clear();
}
