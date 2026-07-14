import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xwidget/src/analytics/analytics.dart';
import 'package:xwidget/src/analytics/analytics_event.dart';
import 'package:xwidget/src/analytics/analytics_store.dart';

/// In-memory store double. Mirrors the real stores' contract: an open
/// "current" file receives writes; rotation closes it into the unsent set;
/// flush reads and deletes unsent files only.
class FakeAnalyticsStore implements AnalyticsStore {
  final unsent = <EventType, Map<String, List<AnalyticsEvent>>>{};
  final current = <EventType, List<AnalyticsEvent>>{};
  String? currentId;
  int _idCounter = 0;

  int unsentFileCount(EventType type) => unsent[type]?.length ?? 0;

  @override
  Future<void> writeEvents(List<AnalyticsEvent> events) async {
    if (events.isEmpty) return;
    currentId ??= 'file${_idCounter++}';
    for (final event in events) {
      final type = EventType.eventTypeFor(event);
      (current[type] ??= []).add(event);
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
    unsent[eventType]?.remove(fileId);
  }

  @override
  Future<void> clear() async {
    unsent.clear();
    current.clear();
    currentId = null;
  }
}

http.Client okClient() => MockClient((_) async => http.Response('{}', 200));
http.Client failClient() => MockClient((_) async => http.Response('boom', 500));

Future<void> flushWith(http.Client Function() client) {
  return http.runWithClient(() => Analytics.instance.flushToServer(), client);
}

/// Startup kicks off an unawaited flush; wait it out before driving
/// cycles, which would otherwise no-op on the in-progress guard.
Future<void> waitForIdle() async {
  while (Analytics.instance.isFlushing) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAnalyticsStore store;

  setUp(() async {
    store = FakeAnalyticsStore();
    await Analytics.initialize(
      projectKey: 'test-project-key',
      channel: 'test',
      version: '1.0.0',
      // Keep the timers far away — tests drive flushes explicitly.
      persistInterval: const Duration(days: 1),
      flushInterval: const Duration(days: 1),
      store: store,
    );
    // Let the unawaited startup flush finish before tests drive cycles.
    await http.runWithClient(waitForIdle, okClient);
  });

  tearDown(() async {
    // Shutdown flushes; keep its network mocked.
    await http.runWithClient(Analytics.shutdown, okClient);
  });

  test('flush persists, sends, and deletes delivered files', () async {
    Analytics.trackRender(fragmentName: 'home');
    await flushWith(okClient);
    expect(store.unsentFileCount(EventType.render), 0, reason: 'sent and deleted');
    expect(store.currentId, isNull, reason: 'current file was rotated');
  });

  test('failed sends retain files for retry', () async {
    Analytics.trackRender(fragmentName: 'home');
    await flushWith(failClient);
    expect(store.unsentFileCount(EventType.render), 1);

    Analytics.trackRender(fragmentName: 'settings');
    await flushWith(failClient);
    expect(store.unsentFileCount(EventType.render), 2);
  });

  test('recovery delivers the whole backlog', () async {
    Analytics.trackRender(fragmentName: 'home');
    await flushWith(failClient);
    Analytics.trackRender(fragmentName: 'settings');
    await flushWith(failClient);
    expect(store.unsentFileCount(EventType.render), 2);

    await flushWith(okClient);
    expect(store.unsentFileCount(EventType.render), 0);
  });
}
