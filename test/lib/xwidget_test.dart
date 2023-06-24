import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xwidget/xwidget.dart';

import '../fixtures/src/inflaters.g.dart';


void main() {

  setUpAll(() {
    registerXWidgetInflaters();
  });

  test('test inherited attributes', () {
    const xml = '''
    <Text data="\${title}" maxLines="2"/>
    ''';
    final textWidget = XWidget.inflateFromXml(
      xml: xml,
      inheritedAttributes: [
        XmlAttribute(XmlName("maxLines"), "3"),
      ],
      dependencies: Dependencies({
        "title": "My Test"
      }),
    );
    expect(textWidget.toString(), 'Text("My Test", maxLines: 3)');
  });
}
