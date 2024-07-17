import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import '../../lib/xwidget.dart';
import '../fixtures/src/inflaters.g.dart';


void main() {

  setUpAll(() {
    registerXWidgetInflaters();
  });

  test('test inherited attributes', () {
    final xml = XmlDocument.parse('<Text data="\${title}" maxLines="2"/>');
    final deps = Dependencies({
      "title": "My Test"
    });
    final textWidget = XWidget.inflateFromXmlElement(xml.rootElement, deps, inheritedAttributes: [
      XmlAttribute(XmlName("maxLines"), "3"),
    ]);
    expect(textWidget.toString(), 'Text("My Test", maxLines: 3)');
  });
}
