import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:xwidget/src/analytics/analytics_event.dart';
import 'package:xwidget/src/analytics/analytics_store_io.dart';

// Durability tests for the file-backed analytics store, against a real temp
// directory: the write→rotate→read→delete contract, the current-file
// exclusion, restart behavior, and the claimed corrupt-line tolerance.
class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

RenderEvent render(String fragment) {
  return RenderEvent(
    channel: "prod",
    version: "1.0.0",
    revision: 1,
    platform: "macos",
    locale: "en_US",
    fragmentName: fragment,
    renderCount: 1,
    errorCount: 0,
    timestamp: DateTime.utc(2026, 7, 13, 10),
  );
}

ErrorEvent errorEvent(String message) {
  return ErrorEvent(
    channel: "prod",
    version: "1.0.0",
    revision: 1,
    platform: "macos",
    locale: "en_US",
    fragmentName: "home",
    errorMessage: message,
    errorCount: 1,
    timestamp: DateTime.utc(2026, 7, 13, 10),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AnalyticsStoreIo store;

  Directory storeDir() => Directory("${tempDir.path}/xwidget_cloud/analytics");

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync("analytics_store_test");
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    store = AnalyticsStoreIo();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test("write, rotate, read, delete round trip", () async {
    await store.writeEvents([render("home"), errorEvent("boom")]);
    await store.rotateFiles();

    final renders = await store.readUnsent(EventType.render);
    final errors = await store.readUnsent(EventType.error);
    expect(renders.length, 1, reason: "one rotated render file");
    expect(renders.values.single.single.toJson()["fragment_name"], "home");
    expect(errors.length, 1, reason: "event types split into separate files");

    await store.deleteFile(EventType.render, renders.keys.single);
    expect(await store.readUnsent(EventType.render), isEmpty);
    expect(
      (await store.readUnsent(EventType.error)).length,
      1,
      reason: "deleting one type leaves the other",
    );
  });

  test("the current (open) file is not readable as unsent", () async {
    await store.writeEvents([render("home")]);
    // No rotation — the file exists on disk but is still open for appends.
    expect(await store.readUnsent(EventType.render), isEmpty);
  });

  test("a restart makes the previous current file sendable", () async {
    await store.writeEvents([render("home")]);

    // New store instance = new process. The old current file has no owner
    // and must become part of the unsent backlog.
    final restarted = AnalyticsStoreIo();
    final unsent = await restarted.readUnsent(EventType.render);
    expect(unsent.length, 1);
    expect(unsent.values.single.single.toJson()["fragment_name"], "home");
  });

  test("corrupt lines are skipped without losing the rest of the file", () async {
    await store.writeEvents([render("home"), render("settings")]);
    await store.rotateFiles();

    final file = storeDir().listSync().whereType<File>().single;
    // Simulate a crash mid-append: garbage and a truncated JSON line.
    file.writeAsStringSync("not json at all\n{\"type\": \"ren", mode: FileMode.append);

    final unsent = await store.readUnsent(EventType.render);
    final names = unsent.values.single.map((e) => e.toJson()["fragment_name"]).toSet();
    expect(names, {"home", "settings"}, reason: "valid lines survive corruption");
  });

  test("clear removes every stored file", () async {
    await store.writeEvents([render("home"), errorEvent("boom")]);
    await store.rotateFiles();
    await store.writeEvents([render("more")]);

    await store.clear();

    expect(await store.readUnsent(EventType.render), isEmpty);
    expect(await store.readUnsent(EventType.error), isEmpty);
    expect(storeDir().listSync().whereType<File>(), isEmpty);
  });
}
