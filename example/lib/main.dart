import 'package:flutter/material.dart';
import 'package:xwidget/xwidget.dart';

import 'package:xwidget_example/xwidget/generated/controllers.g.dart';
import 'package:xwidget_example/xwidget/generated/icons.g.dart';
import 'package:xwidget_example/xwidget/generated/inflaters.g.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // load resources
  await Resources.instance.loadResources("resources");

  // register XWidget components
  registerXWidgetIcons();
  registerXWidgetInflaters();
  registerXWidgetControllers();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  // See 'resources/fragments/my_app.xml' for the example fragment. You can break up your
  // UI into fragments and reuse them, iterate over them, use control tags on them, etc.
  @override
  Widget build(BuildContext context) {
    return XWidget.inflateFragment("my_app", Dependencies());
  }
}
