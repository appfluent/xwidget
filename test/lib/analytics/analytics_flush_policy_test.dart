import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xwidget/src/analytics/analytics.dart';
import 'package:xwidget/src/analytics/analytics_event.dart';
import 'package:xwidget/src/analytics/analytics_store.dart';

// Flush-policy tests: staleness discard at maxFileAge, per-event-type send
// independence, and the distinct-error cap.
class FakeAnalyticsStore implements AnalyticsStore {
  final unsent = <EventType, Map<String, List<AnalyticsEvent>>>{};
  final current = <EventType, List<AnalyticsEvent>>{};
  final deleted = <String>[];
  String? currentId;

  /// Preloads a closed (unsent) file, as if persisted in an earlier session.
  void preload(EventType type, String fileId, List<AnalyticsEvent> events) {
    (unsent[type] ??= {})[fileId] = events;
  }

  @override
  Future<void> writeEvents(List<AnalyticsEvent> events) async {
    if (events.isEmpty) return;
    currentId ??= DateTime.now().millisecondsSinceEpoch.toString();
    for (final event in events) {
      (current[EventType.eventTypeFor(event)] ??= []).add(event);
    }
  }

  @override
  Future<void> rotateFiles() async {
    final id = currentId;
    if (id == null) return;
    for (final entry in current.entries) {
      if (entry.value.isEmpty) continue;
      (unsent[entry.key] ??= {})[id] = List.of(entry.value);
    }
    current.clear();
    currentId = null;
  }

  @override
  Future<Map<String, List<AnalyticsEvent>>> readUnsent(EventType eventType) async {
    return Map.of(unsent[eventType] ?? {});
  }

  @override
  Future<void> deleteFile(EventType eventType, String fileId) async {
    deleted.add("${eventType.name}:$fileId");
    unsent[eventType]?.remove(fileId);
  }

  @override
  Future<void> clear() async {
    unsent.clear();
    current.clear();
    currentId = null;
  }
}

RenderEvent render(String fragment) {
  return RenderEvent(
    channel: "test",
    version: "1.0.0",
    revision: 1,
    platform: "macos",
    locale: "en_US",
    fragmentName: fragment,
    renderCount: 1,
    errorCount: 0,
    timestamp: DateTime.now().toUtc(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAnalyticsStore store;
  // Requests captured by the mock client, keyed by endpoint path.
  late Map<String, List<Map<String, dynamic>>> sent;

  http.Client recordingClient({Set<String> failPaths = const {}}) {
    return MockClient((request) async {
      final events = (jsonDecode(request.body)["events"] as List).cast<Map<String, dynamic>>();
      (sent[request.url.path] ??= []).addAll(events);
      return failPaths.contains(request.url.path)
          ? http.Response("boom", 500)
          : http.Response("{}", 200);
    });
  }

  Future<void> flushWith(http.Client client) {
    return http.runWithClient(() => Analytics.instance.flushToServer(), () => client);
  }

  Future<void> waitForIdle() async {
    while (Analytics.instance.isFlushing) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    store = FakeAnalyticsStore();
    sent = {};
    await Analytics.initialize(
      projectKey: "test-project-key",
      channel: "test",
      version: "1.0.0",
      persistInterval: const Duration(days: 1),
      flushInterval: const Duration(days: 1),
      maxFileAge: const Duration(days: 7),
      store: store,
    );
    await http.runWithClient(waitForIdle, () => recordingClient());
    sent = {};
    store.deleted.clear();
  });

  tearDown(() async {
    await http.runWithClient(Analytics.shutdown, () => recordingClient());
  });

  test("files older than maxFileAge are discarded unsent", () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final staleId = "${now - const Duration(days: 8).inMilliseconds}";
    final freshId = "${now - const Duration(hours: 1).inMilliseconds}";
    store.preload(EventType.render, staleId, [render("stale-fragment")]);
    store.preload(EventType.render, freshId, [render("fresh-fragment")]);

    await flushWith(recordingClient());

    final sentFragments = (sent["/ingest/renders"] ?? []).map((e) => e["fragment_name"]).toSet();
    expect(sentFragments, {"fresh-fragment"}, reason: "stale events never sent");
    expect(store.deleted, contains("render:$staleId"));
    expect(store.deleted, contains("render:$freshId"));
    expect(store.unsent[EventType.render], isEmpty);
  });

  test("a failing endpoint does not block other event types", () async {
    final id = "${DateTime.now().millisecondsSinceEpoch - 1000}";
    store.preload(EventType.render, id, [render("home")]);
    store.preload(EventType.error, id, [
      ErrorEvent(
        channel: "test",
        version: "1.0.0",
        revision: 1,
        platform: "macos",
        locale: "en_US",
        fragmentName: "home",
        errorMessage: "boom",
        errorCount: 1,
        timestamp: DateTime.now().toUtc(),
      ),
    ]);

    await flushWith(recordingClient(failPaths: {"/ingest/errors"}));

    expect(store.unsent[EventType.render], isEmpty, reason: "renders delivered and deleted");
    expect(store.unsent[EventType.error]?.length, 1, reason: "errors retained for retry");
  });

  test("distinct errors are capped in the buffer", () async {
    for (var i = 0; i < 60; i++) {
      Analytics.trackError(error: "distinct error $i");
    }

    await flushWith(recordingClient());

    final errorEvents = sent["/ingest/errors"] ?? [];
    expect(errorEvents.length, 50, reason: "buffer caps distinct errors at 50");
  });

  test("repeats of an existing error merge past the cap", () async {
    for (var i = 0; i < 50; i++) {
      Analytics.trackError(error: "distinct error $i");
    }
    // At the cap: repeats of a buffered error must still count.
    Analytics.trackError(error: "distinct error 0");
    Analytics.trackError(error: "distinct error 0");

    await flushWith(recordingClient());

    final first = (sent["/ingest/errors"] ?? []).firstWhere(
      (e) => (e["error_message"] as String).endsWith(" 0"),
    );
    expect(first["error_count"], 3, reason: "merges bypass the distinct cap");
  });
}
