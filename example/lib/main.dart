import 'package:flutter/material.dart';
import 'package:xwidget/xwidget.dart';
import 'package:xwidget_example/xwidget/generated/registry.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local resources, no analytics (default)
  await XWidget.initialize(register: registerXWidgetComponents);

  // Cloud settings should be loaded from Firebase's Remote Config
  // or similar service.

  // Cloud resources and analytics
  // See https://docs.xwidget.dev/latest/runtime/cloud_resources/
  // await XWidget.initialize(
  //     register: registerXWidgetComponents,
  //     resources: CloudResources(
  //         projectKey: "<projectKey>",
  //         storageKey: "<storageKey>",
  //         channel: "<channel>",
  //         version: "<version>"
  //     )
  // );

  // Local resources with cloud analytics
  // See https://docs.xwidget.dev/latest/runtime/local_resources/
  // await XWidget.initialize(
  //     register: registerXWidgetComponents,
  //     resources: LocalResources.withAnalytics(
  //         projectKey: "<projectKey>",
  //         version: "<version>"
  //     )
  // );

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
