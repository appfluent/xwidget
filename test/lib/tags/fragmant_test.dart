import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xwidget/xwidget.dart';

import '../../fixtures/src/inflaters.g.dart';
import '../testing_utils.dart';

main() {
  final assetBundle = TestAssetBundle([
    "test/fixtures/resources"
  ]);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Resources.instance.loadResources("test/fixtures/resources", assetBundle);
    registerXWidgetInflaters();
  });

  test('test fragment attributes', () {
    final Text widget = XWidget.inflateFragment("text", Dependencies({
      "title": "Hello world!"
    }));
    expect(widget.toString(), 'Text("Hello world!")');
  });

  test('test fragment parameters', () {
    final Text widget = XWidget.inflateFragment("text?title=Hello world!", Dependencies());
    expect(widget.toString(), 'Text("Hello world!")');
  });

  test('test fragment inherited attributes', () {
    final xml = XmlDocument.parse('<Column><fragment name="text" maxLines="3"/></Column>');
    final Column widget = XWidget.inflateFromXmlElement(xml.rootElement, Dependencies({
      "title": "Hello world!"
    }));
    expect(widget.children.toString(), '[Text("Hello world!", maxLines: 3)]');
  });
}
