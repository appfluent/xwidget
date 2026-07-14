import 'package:flutter_test/flutter_test.dart';
import 'package:xwidget/src/analytics/analytics_event.dart';

// Aggregation semantics: events with the same dimensions and hour merge into
// one counter; anything crossing a dimension or hour boundary stays separate.
RenderEvent render(String fragment, DateTime time, {int renders = 1, int errors = 0}) {
  return RenderEvent(
    channel: "prod",
    version: "1.0.0",
    revision: 4,
    platform: "macos",
    locale: "en_US",
    fragmentName: fragment,
    renderCount: renders,
    errorCount: errors,
    timestamp: time,
  );
}

ErrorEvent error(String message, DateTime time) {
  return ErrorEvent(
    channel: "prod",
    version: "1.0.0",
    revision: 4,
    platform: "macos",
    locale: "en_US",
    fragmentName: "home",
    errorMessage: message,
    errorCount: 1,
    timestamp: time,
  );
}

void main() {
  final tenAm = DateTime.utc(2026, 7, 13, 10, 15);
  final tenThirty = DateTime.utc(2026, 7, 13, 10, 45);
  final elevenAm = DateTime.utc(2026, 7, 13, 11, 15);

  group("aggregation keys", () {
    test("same dimensions in the same hour share a key", () {
      expect(render("home", tenAm).aggregationKey, render("home", tenThirty).aggregationKey);
    });

    test("hour boundaries split keys", () {
      expect(render("home", tenAm).aggregationKey, isNot(render("home", elevenAm).aggregationKey));
    });

    test("fragment name splits keys", () {
      expect(render("home", tenAm).aggregationKey, isNot(render("settings", tenAm).aggregationKey));
    });

    test("distinct error messages split keys, identical ones share", () {
      expect(error("boom", tenAm).aggregationKey, error("boom", tenThirty).aggregationKey);
      expect(error("boom", tenAm).aggregationKey, isNot(error("crash", tenAm).aggregationKey));
    });
  });

  group("mergeFrom", () {
    test("render counters sum", () {
      final target = render("home", tenAm, renders: 2, errors: 1);
      target.mergeFrom(render("home", tenThirty, renders: 3, errors: 0));
      expect(target.renderCount, 5);
      expect(target.errorCount, 1);
    });

    test("error counters sum", () {
      final target = error("boom", tenAm);
      target.mergeFrom(error("boom", tenThirty));
      expect(target.errorCount, 2);
    });

    test("mismatched event types are ignored, not crashed on", () {
      final target = render("home", tenAm);
      target.mergeFrom(error("boom", tenAm));
      expect(target.renderCount, 1);
    });
  });

  group("event typing", () {
    test("eventTypeFor maps events to their storage type", () {
      expect(EventType.eventTypeFor(render("home", tenAm)), EventType.render);
      expect(EventType.eventTypeFor(error("boom", tenAm)), EventType.error);
    });

    test("error messages truncate at the cap", () {
      final long = "x" * 2000;
      expect(error(long, tenAm).errorMessage.length, ErrorEvent.maxMessageLength);
    });
  });
}
