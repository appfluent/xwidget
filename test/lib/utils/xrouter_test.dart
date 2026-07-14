import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xwidget/src/utils/router/xrouter.dart';

// Route parsing and resolution tests. All loads use the same source id, so
// each load replaces the previous test's routes (XRouter keeps static state;
// per-source replacement is the built-in isolation mechanism).
void load(String body, {String attrs = '', String source = "t"}) {
  XRouter.loadRoutesFromXml(
    source,
    XmlDocument.parse('<routes xmlns="https://xwidget.dev/routes" $attrs>$body</routes>'),
  );
}

void main() {
  group("parsing validation", () {
    test("route requires a path", () {
      expect(() => load('<route fragment="a"/>'), throwsException);
    });

    test("path must start with a slash", () {
      expect(() => load('<route path="users" fragment="a"/>'), throwsException);
    });

    test("path rejects double and trailing slashes", () {
      expect(() => load('<route path="/a//b" fragment="a"/>'), throwsException);
      expect(() => load('<route path="/a/" fragment="a"/>'), throwsException);
    });

    test("route requires fragment or redirect, not neither", () {
      expect(() => load('<route path="/a"/>'), throwsException);
    });

    test("route rejects fragment and redirect together", () {
      expect(() => load('<route path="/a" fragment="f" redirect="/b"/>'), throwsException);
    });

    test("redirect must start with a slash", () {
      expect(() => load('<route path="/a" redirect="b"/>'), throwsException);
    });

    test("routeGroup requires a name", () {
      expect(
        () => load('<routeGroup><route path="/a" fragment="f"/></routeGroup>'),
        throwsException,
      );
    });

    test("duplicate paths collide", () {
      expect(
        () => load('<route path="/a" fragment="f1"/><route path="/a" fragment="f2"/>'),
        throwsException,
      );
    });

    test("duplicate names collide", () {
      expect(
        () => load(
          '<route path="/dupname-a" name="dup" fragment="f1"/>'
          '<route path="/dupname-b" name="dup" fragment="f2"/>',
        ),
        throwsException,
      );
    });

    test("a failed load leaves no partially registered routes", () {
      // Loads are atomic: the duplicate-name document above registered
      // nothing, so nothing from it can shadow or collide later.
      load('<route path="/clean" fragment="f"/>');
      expect(
        XRouter.resolve("/dupname-b"),
        isNull,
        reason: "zombie route from the failed load must not survive",
      );
    });

    test("a failed reload preserves the previous routes", () {
      load('<route path="/keep" fragment="keep_frag"/>');
      expect(
        () => load('<route path="/x" fragment="f1"/><route path="/x" fragment="f2"/>'),
        throwsException,
      );
      expect(
        XRouter.resolve("/keep")?.fragment,
        "keep_frag",
        reason: "a bad reload must change nothing",
      );
      expect(XRouter.resolve("/x"), isNull);
    });
  });

  group("basic resolution", () {
    test("exact path match", () {
      load('<route path="/home" name="home" fragment="home_frag"/>');
      final route = XRouter.resolve("/home");
      expect(route?.fragment, "home_frag");
      expect(route?.path, "/home");
      expect(route?.name, "home");
    });

    test("name match", () {
      load('<route path="/home" name="home" fragment="home_frag"/>');
      expect(XRouter.resolve("home")?.fragment, "home_frag");
    });

    test("unknown target resolves to null", () {
      load('<route path="/home" fragment="f"/>');
      expect(XRouter.resolve("/nope"), isNull);
      expect(XRouter.resolve("nope"), isNull);
    });

    test("query parameters are stripped for matching and kept as params", () {
      load('<route path="/search" fragment="f"/>');
      final route = XRouter.resolve("/search?q=hello&page=2");
      expect(route?.fragment, "f");
      expect(route?.params, {"q": "hello", "page": "2"});
    });

    test("repeated interior slashes in the target are normalized", () {
      load('<route path="/a/b" fragment="f"/>');
      expect(XRouter.resolve("/a///b")?.fragment, "f");
    });

    test("a leading double slash is a path, not a URI authority", () {
      // Slashes collapse before Uri.parse, so "//a" can never be misread
      // as an authority (host) named "a".
      load('<route path="/a/b" fragment="f"/>');
      expect(XRouter.resolve("//a///b")?.fragment, "f");
    });

    test("slash collapsing never touches query values", () {
      load('<route path="/redirect" fragment="f"/>');
      final route = XRouter.resolve("/redirect//extra//?next=https://x.com//y");
      expect(route, isNull, reason: "collapsed path /redirect/extra/ has no route");

      final clean = XRouter.resolve("//redirect?next=https://x.com//y");
      expect(clean?.fragment, "f");
      expect(clean?.params, {
        "next": "https://x.com//y",
      }, reason: "query values keep their double slashes");
    });
  });

  group("parameterized routes", () {
    test("path parameters are extracted", () {
      load('<route path="/users/:id" fragment="user_frag"/>');
      final route = XRouter.resolve("/users/42");
      expect(route?.fragment, "user_frag");
      expect(route?.params, {"id": "42"});
    });

    test("multiple parameters and query params merge", () {
      load('<route path="/orgs/:org/repos/:repo" fragment="f"/>');
      final route = XRouter.resolve("/orgs/acme/repos/xwidget?tab=issues");
      expect(route?.params, {"org": "acme", "repo": "xwidget", "tab": "issues"});
    });

    test("exact matches win over patterns", () {
      load(
        '<route path="/users/:id" fragment="pattern_frag"/>'
        '<route path="/users/me" fragment="exact_frag"/>',
      );
      expect(XRouter.resolve("/users/me")?.fragment, "exact_frag");
      expect(XRouter.resolve("/users/7")?.fragment, "pattern_frag");
    });
  });

  group("redirects", () {
    test("redirect resolves to the destination route", () {
      load(
        '<route path="/old" redirect="/new"/>'
        '<route path="/new" fragment="new_frag"/>',
      );
      final route = XRouter.resolve("/old");
      expect(route?.fragment, "new_frag");
      expect(route?.path, "/new");
    });

    test("redirect carries path parameters into the destination", () {
      load(
        '<route path="/u/:id" redirect="/users/:id"/>'
        '<route path="/users/:id" fragment="user_frag"/>',
      );
      final route = XRouter.resolve("/u/42");
      expect(route?.fragment, "user_frag");
      expect(route?.params, {"id": "42"});
    });

    test("redirect with an undefined parameter throws", () {
      // A non-parameterized route has no values to substitute, so a
      // placeholder in its redirect destination is unresolvable and must
      // throw — not pass through literally and "match" the destination's
      // own pattern with ":missing" as the parameter value.
      load(
        '<route path="/a" redirect="/x/:missing"/>'
        '<route path="/x/:missing" fragment="f"/>',
      );
      expect(() => XRouter.resolve("/a"), throwsException);
    });

    test("redirect loops hit the redirect limit", () {
      load(
        '<route path="/ping" redirect="/pong"/>'
        '<route path="/pong" redirect="/ping"/>',
      );
      expect(
        () => XRouter.resolve("/ping"),
        throwsA(
          isA<Exception>().having((e) => e.toString(), "message", contains("Too many redirects")),
        ),
      );
    });

    test("maxRedirects attribute lowers the limit", () {
      load(
        '<route path="/mr-a" redirect="/mr-b"/>'
        '<route path="/mr-b" redirect="/mr-c"/>'
        '<route path="/mr-c" fragment="f"/>',
        attrs: 'maxRedirects="1"',
      );
      expect(() => XRouter.resolve("/mr-a"), throwsException);
      // A later load without the attribute restores the default.
      load('<route path="/p" fragment="f"/>');
      expect(XRouter.maxRedirects, 5);
    });
  });

  group("route groups", () {
    const group = '''
      <routeGroup name="main" path="/main" history="false" presenter="panel"
                  transition="fade">
        <route path="/stats" name="stats" fragment="stats_frag"/>
        <route path="/settings" name="settings" fragment="settings_frag"
               history="true" transition="slide"/>
      </routeGroup>
    ''';

    test("group name and path prefix child routes", () {
      load(group);
      final route = XRouter.resolve("/main/stats");
      expect(route?.fragment, "stats_frag");
      expect(route?.name, "main:stats");
      expect(XRouter.resolve("main:settings")?.fragment, "settings_frag");
    });

    test("view indexes follow document order", () {
      load(group);
      expect(XRouter.resolve("/main/stats")?.viewIndex, 0);
      expect(XRouter.resolve("/main/settings")?.viewIndex, 1);
      expect(XRouter.resolve("/main/stats")?.groupName, "main");
    });

    test("group name and group path alias the first child", () {
      load(group);
      expect(XRouter.resolve("main")?.fragment, "stats_frag");
      expect(XRouter.resolve("/main")?.fragment, "stats_frag");
    });

    test("children inherit group settings and can override them", () {
      load(group);
      final stats = XRouter.resolve("/main/stats");
      expect(stats?.history, false);
      expect(stats?.presenter, "panel");
      expect(stats?.transition, "fade");

      final settings = XRouter.resolve("/main/settings");
      expect(settings?.history, true, reason: "route-level override");
      expect(settings?.transition, "slide", reason: "route-level override");
      expect(settings?.presenter, "panel", reason: "inherited");
    });

    test("nested groups concatenate paths and build the ancestor chain", () {
      load('''
        <routeGroup name="app" path="/app">
          <route path="/home" name="home" fragment="home_frag"/>
          <routeGroup name="reports" path="/reports" fragment="reports_frag">
            <route path="/daily" name="daily" fragment="daily_frag"/>
          </routeGroup>
        </routeGroup>
      ''');
      final route = XRouter.resolve("/app/reports/daily");
      expect(route?.fragment, "daily_frag");
      expect(route?.groupName, "reports");
      expect(route?.ancestors.length, 1);
      expect(route?.ancestors.single.groupName, "app");
      expect(
        route?.ancestors.single.viewIndex,
        1,
        reason: "the nested group occupies view slot 1 in its parent",
      );
    });
  });

  group("reload semantics", () {
    test("reloading a source replaces its routes", () {
      load('<route path="/first" fragment="f1"/>');
      expect(XRouter.resolve("/first")?.fragment, "f1");

      load('<route path="/second" fragment="f2"/>');
      expect(XRouter.resolve("/first"), isNull, reason: "old routes removed");
      expect(XRouter.resolve("/second")?.fragment, "f2");
    });

    test("sources replace independently", () {
      load('<route path="/from-t" fragment="ft"/>');
      load('<route path="/from-u" fragment="fu"/>', source: "u");

      // Reloading source t must not disturb source u's routes.
      load('<route path="/from-t2" fragment="ft2"/>');
      expect(XRouter.resolve("/from-t"), isNull);
      expect(XRouter.resolve("/from-t2")?.fragment, "ft2");
      expect(XRouter.resolve("/from-u")?.fragment, "fu");

      // Clean up source u so later runs start fresh.
      load('<route path="/u-cleanup" fragment="f"/>', source: "u");
    });
  });
}
