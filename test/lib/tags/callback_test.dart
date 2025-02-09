import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xwidget/xwidget.dart';

import '../../fixtures/src/inflaters.g.dart';
import '../testing_utils.dart';

main() {
  final assetBundle = TestAssetBundle([
    "test/fixtures/res"
  ]);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Resources.instance.loadResources("test/fixtures/res", assetBundle);
    registerXWidgetInflaters();
  });

  testWidgets('Assert callback action on TextButton fires', (tester) async {
    final xml = XmlDocument.parse('''
      <MaterialApp>
        <Scaffold for="home">
          <Column for="body">
            <TextButton>
              <callback for="onPressed" action="doSomething('Hello world!')" returnVar="result"/>                 
              <Text data="Press Me"/>
            </TextButton>
          </Column>
        </Scaffold>
      </MaterialApp>
    ''');

    final dependencies = Dependencies({
      "doSomething": (msg)  => "Your message: $msg"
    });

    final testApp = XWidget.inflateFromXmlElement(xml.rootElement, dependencies);
    await tester.pumpWidget(testApp);
    await tester.tap(find.byType(TextButton));
    expect(dependencies["result"], "Your message: Hello world!");
  });
}