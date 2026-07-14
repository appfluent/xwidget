import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xwidget/src/utils/resources/value_bundle.dart';
import 'package:xwidget/src/utils/router/xrouter.dart';

// Regression tests for the 0.7.0 localName dispatch fix: values and routes
// documents must parse identically whether they use a default namespace, a
// namespace prefix, or no namespace at all.
void main() {
  const values = '''
    <string name="title">Hello</string>
    <int name="count">3</int>
    <bool name="enabled">true</bool>
    <color name="accent">#FF0000</color>
  ''';

  void expectParsed(ValueResourceBundle bundle) {
    expect(bundle.getString("title"), "Hello");
    expect(bundle.getInt("count"), 3);
    expect(bundle.getBool("enabled"), true);
    expect(bundle.getColor("accent"), const Color(0xFFFF0000));
  }

  group("values documents", () {
    test("parse without a namespace (pre-0.7 files)", () {
      final bundle = ValueResourceBundle("values");
      bundle.loadFromString("res/values", "strings", "xml", "<resources>$values</resources>");
      expectParsed(bundle);
    });

    test("parse with the default namespace", () {
      final bundle = ValueResourceBundle("values");
      bundle.loadFromString(
        "res/values",
        "strings",
        "xml",
        '<resources xmlns="https://xwidget.dev/values">$values</resources>',
      );
      expectParsed(bundle);
    });

    test("parse with a namespace prefix", () {
      final bundle = ValueResourceBundle("values");
      bundle.loadFromString(
        "res/values",
        "strings",
        "xml",
        '<v:resources xmlns:v="https://xwidget.dev/values">'
            '<v:string name="title">Hello</v:string>'
            '<v:int name="count">3</v:int>'
            '<v:bool name="enabled">true</v:bool>'
            '<v:color name="accent">#FF0000</v:color>'
            '</v:resources>',
      );
      expectParsed(bundle);
    });
  });

  group("routes documents", () {
    test("load with the default namespace", () {
      XRouter.loadRoutesFromXml(
        "test-default",
        XmlDocument.parse(
          '<routes xmlns="https://xwidget.dev/routes">'
          '<route path="/vb-default" fragment="home"/>'
          '</routes>',
        ),
      );
      expect(XRouter.resolve("/vb-default")?.fragment, "home");
    });

    test("load with a namespace prefix", () {
      XRouter.loadRoutesFromXml(
        "test-prefixed",
        XmlDocument.parse(
          '<r:routes xmlns:r="https://xwidget.dev/routes">'
          '<r:route path="/vb-prefixed" fragment="home"/>'
          '</r:routes>',
        ),
      );
      expect(XRouter.resolve("/vb-prefixed")?.fragment, "home");
    });

    test("load via a values file with a routes root", () {
      final bundle = ValueResourceBundle("values");
      bundle.loadFromString(
        "res/values",
        "routes",
        "xml",
        '<routes xmlns="https://xwidget.dev/routes">'
            '<route path="/vb-viafile" fragment="home"/>'
            '</routes>',
      );
      expect(XRouter.resolve("/vb-viafile")?.fragment, "home");
    });
  });
}
