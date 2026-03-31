import 'package:flutter/material.dart';
import 'package:xwidget/xwidget.dart';

import 'xwidget/generated/controllers.g.dart';
import 'xwidget/generated/icons.g.dart';
import 'xwidget/generated/inflaters.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cloud settings should be loaded from Firebase's Remote Config
  // or similar service.
  await XWidget.initialize(
    projectKey: '<your-project-key>',
    storageKey: '<your-storage-key>',
    channel: 'dev',
    version: '1.0.1',
  );

  // register XWidget components
  registerXWidgetIcons();
  registerXWidgetInflaters();
  registerXWidgetControllers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  // See 'resources/fragments/my_app.xml' for the example fragment. You
  // can break up your UI into fragments and reuse them, iterate over them,
  // use control tags on them, etc.
  @override
  Widget build(BuildContext context) {
    return XWidget.inflateFragment("my_app", Dependencies());
  }
}
