<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget/main/doc/assets/xwidget_logo_full.png"
        alt="XWidget Logo"
        height="96"
    />
</p>

<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget/main/doc/assets/code_animation.gif"
        alt="XWidget XML authoring demo"
        style="max-width:800px; width:100%; height:auto;"
    />
</p>

# What is XWidget?

XWidget is a server-driven UI platform for Flutter. It lets you move
presentation resources out of the app binary and into versioned UI bundles that
can be deployed through XWidget Cloud, while your compiled Flutter app keeps
control of behavior, services, credentials, permissions, business rules, and
native integrations.

> XML is the markup. Bundles are the transport. Flutter remains the runtime.

Use XWidget when you need to:

- Update screens without shipping a new app build
- Run A/B tests, staged rollouts, and channel-based releases
- Keep UI moving while app store review and user update cycles catch up
- Ship dynamic layout, copy, styling, resources, and routes from a content server
- Keep app behavior in Dart instead of moving business logic into markup

## Flutter First

You use generated inflaters for the Flutter SDK, third-party packages, and your own widgets.
XWidget Builder reads Dart specs and generates the runtime registration code,
XML schema, icons, controllers, and IDE metadata your app uses at build time.

That means your server-driven UI can use the widgets your Flutter app already
uses.

## Markup That Looks Like UI

XWidget fragments are XML files that map closely to Flutter widget trees. They
support nested fragments, parameters, control flow, resources, expressions, and
dependency scopes.

```xml
<Column xmlns="http://www.appfluent.us/xwidget" crossAxisAlignment="start">
    <Text data="Hello World">
        <TextStyle for="style" fontWeight="bold" color="#262626"/>
    </Text>

    <if test="${items.length > 0}">
        <Text data="Found ${items.length} items"/>
    </if>
</Column>
```

Inflate a fragment from Dart:

```dart
@override
Widget build(BuildContext context) {
  return XWidget.inflateFragment<Widget>('home', Dependencies())!;
}
```

## Dart Owns Behavior

Controllers keep behavior in Dart. Fragments bind to controller state and
callbacks through dependencies, `ValueListener`, and `EventListener`.

```xml
<Controller name="CounterController">
    <ValueListener varName="count">
        <Text data="${toString(count)}"/>
    </ValueListener>
</Controller>
```

This keeps UI presentation flexible without turning markup into your application
runtime.

## Production SDUI

XWidget Cloud delivers fragments, value resources, and routes as versioned UI
bundles. Deploy to the cloud, then publish to a channel — test, staging,
production — you decide the workflow. Apps can select channels and versions
through remote configuration for beta users, rollouts, A/B cohorts, or pinned
releases.

```dart
await XWidget.initialize(
  register: registerXWidgetComponents,
  resources: CloudResources(
    projectKey: '<your-project-key>',
    storageKey: '<your-storage-key>',
    channel: remoteConfig.xwidgetChannel,
    version: remoteConfig.xwidgetVersion,
  ),
);
```

When connected to XWidget Cloud, XWidget can also track fragment renders, bundle
downloads, errors, and navigation transitions without manual instrumentation.

## What Can Change Remotely

XWidget is designed for presentation resources:

- Screens and reusable fragments
- Layout and visual structure
- Copy and static resources
- Colors, dimensions, and style resources
- Route definitions and navigation targets
- Experiment variants and release-channel differences

Your Flutter app should still own sensitive and platform-bound behavior:
credentials, native permissions, service integrations, critical business rules,
and anything that must remain inside the compiled app.

## Quick Start

Add the builder dev dependency:

```bash
flutter pub add dev:xwidget_builder
```

Initialize a new XWidget starter app:

```bash
dart run xwidget_builder:init --new-app
dart run xwidget_builder:generate
```

For an existing Flutter app, omit `--new-app`:

```bash
dart run xwidget_builder:init
dart run xwidget_builder:generate
```

Register generated components before calling `runApp()`:

```dart
import 'package:flutter/material.dart';
import 'package:xwidget/xwidget.dart';

import 'xwidget/generated/registry.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await XWidget.initialize(register: registerXWidgetComponents);

  runApp(const MyApp());
}
```

## Features

- **Generated widget support** - Flutter SDK widgets, package widgets, and app
  widgets can be exposed to XML through generated inflaters.
- **Expression language** - Bind XML attributes to dynamic values, properties,
  operators, functions, custom functions, and resources.
- **Fragments** - Compose screens from reusable XML fragments with nested
  dependencies and parameters.
- **Controllers** - Keep state and behavior in Dart while fragments render the
  presentation layer.
- **Resources** - Load reusable strings, colors, numbers, booleans, and routes
  from XML value files.
- **Routing** - Define routes in XML and navigate from Dart or XML, including
  callback route groups for `PageView`, `TabBarView`, and `IndexedStack`.
- **Cloud delivery** - Load versioned bundles from XWidget Cloud through
  channels and pinned versions.
- **Analytics** - Track renders, downloads, errors, and navigation transitions
  when using XWidget Cloud.
- **Cross-platform** - Works on Flutter's supported platforms: iOS, Android,
  web, Windows, macOS, and Linux.

## Documentation

Full documentation is available at **[docs.xwidget.dev](https://docs.xwidget.dev)**,
including:

- [Introduction](https://docs.xwidget.dev/getting_started/introduction/) -
  server-driven Flutter with XWidget
- [Quick Start](https://docs.xwidget.dev/getting_started/quick_start/) -
  installation and setup
- [Guided Setup](https://docs.xwidget.dev/guides/guided_setup/) - a fuller
  walkthrough from local resources to cloud delivery
- [Fragments](https://docs.xwidget.dev/concepts/fragments/) - XML-based UI
  components
- [Controllers](https://docs.xwidget.dev/concepts/controllers/) - state and
  behavior in Dart
- [Resources](https://docs.xwidget.dev/concepts/resources/) - strings, colors,
  numbers, booleans, and routes
- [Routing](https://docs.xwidget.dev/concepts/routing/) - route XML,
  navigation, and web URL sync
- [Expression Language](https://docs.xwidget.dev/el/rules/) - operators,
  functions, and custom logic
- [Server-Driven UI](https://docs.xwidget.dev/concepts/server_driven_ui/) -
  runtime delivery model
- [Cloud Resources](https://docs.xwidget.dev/runtime/cloud_resources/) -
  over-the-air UI delivery
- [Analytics](https://docs.xwidget.dev/analytics/overview/) - downloads,
  renders, errors, and transitions
- [Code Generation](https://docs.xwidget.dev/builder/overview/) - inflaters,
  icons, controllers, registry, and schema

## IDE Plugins

- [Flutter XWidget for Android Studio / IntelliJ](https://plugins.jetbrains.com/plugin/25494-flutter-xwidget)
- [Flutter XWidget for VS Code](https://marketplace.visualstudio.com/items?itemName=appfluent.flutter-xwidget)

The plugins add EL syntax highlighting, contextual navigation, component
generation, and hot reload for fragments and resource values.

## License

See [LICENSE](LICENSE) for details.
