<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget/main/doc/assets/xwidget_logo_full.png"
        alt="XWidget Logo"
        height="80"
    />
</p>

<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget/main/doc/assets/code_animation.gif"
        alt="Code Animation"
        style="max-width:800px; width:100%; height:auto;"
    />
</p>

# XWidget

XWidget is a Flutter runtime for building dynamic UI from an expressive XML
markup language. It lets you keep application behavior in Dart while moving
layout, copy, styling, resources, and route definitions into XML that can be
loaded from local assets or XWidget Cloud.

```xml
<Column xmlns="http://www.appfluent.us/xwidget" crossAxisAlignment="start">
    <Text data="Hello World">
        <TextStyle for="style" fontWeight="bold" color="#262626"/>
    </Text>
    <Text>Welcome to XWidget!</Text>
</Column>
```

Use XWidget when you need to:

- Update screens without shipping a new app build
- Run A/B tests and gradual UI rollouts
- Keep UI consistent across platforms despite app store review and user update cycles
- Engage users with timely content across approval and update-cycle delays
- Share dynamic layout, static resources, and route definitions across app versions

## Features

### Dynamic UI Fragments

Define UI in XML and inflate it at runtime. Compose screens from reusable
fragments with nesting, parameters, control flow, and inherited dependencies.

```dart
@override
Widget build(BuildContext context) {
  return XWidget.inflateFragment<Widget>('home', Dependencies())!;
}
```

### Generated Flutter Widget Support

Use generated inflaters for Flutter widgets, package widgets, and your own
custom widgets. XWidget Builder reads Dart specs and generates the runtime
registration code, XML schema, and IDE metadata your app uses at build time.

### Expression Language

Write dynamic expressions directly in XML. XWidget expressions support
operators, built-in functions, custom functions, resource accessors, and values
from your dependency scope.

```xml
<Text data="${user.firstName + ' ' + user.lastName}"/>
<Text visible="${items.length > 0}" data="Found ${items.length} items"/>
<Container color="${isActive ? toColor('#00FF00') : toColor('#FF0000')}"/>
```

### State Management

Keep business logic in Dart with controllers, then bind XML to controller state
using `ValueListener`, `EventListener`, dependency scopes, and callbacks.

```xml
<Controller name="CounterController">
    <ValueListener varName="count">
        <Text data="${toString(count)}"/>
    </ValueListener>
</Controller>
```

### Static Resources

Load reusable string, color, int, double, and bool resources from XML value
files. Access them from expressions with functions such as `resString()` and
`resColor()`.

```xml
<Text data="${resString('app_title')}"/>
<Container color="${resColor('primary')}"/>
```

### Routing

Define routes in XML value resources and navigate from Dart or XML. XWidget
supports Navigator-backed routes, callback route groups for `PageView`,
`TabBarView`, and `IndexedStack`, path/query parameters, browser history, and
startup deep links on web.

```xml
<routes>
    <route path="/product/:id" name="product" fragment="product_detail"/>
</routes>
```

```xml
<TextButton onPressed="${routeTo('/product/42?tab=reviews')}">
    <Text>View product</Text>
</TextButton>
```

### Server-Driven UI

Load fragments, value resources, and routes from XWidget Cloud. Deploy to a
staging channel, test, then promote to production without waiting for app store
review.

```dart
await XWidget.initialize(
  register: registerXWidgetComponents,
  resources: CloudResources(
    projectKey: '<your-project-key>',
    storageKey: '<your-storage-key>',
    channel: 'production',
    version: '1.0.0',
  ),
);
```

### Automatic Analytics

When connected to XWidget Cloud, XWidget can track fragment renders, bundle
downloads, errors, and navigation transitions without manual instrumentation.

### Cross-Platform

Works on Flutter's supported platforms: iOS, Android, web, Windows, macOS, and
Linux.

## Quick Start

Install XWidget and the code generator:

```bash
flutter pub add xwidget dev:xwidget_builder
```

Initialize a new XWidget app:

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

## Documentation

Full documentation is available at **[docs.xwidget.dev](https://docs.xwidget.dev)**,
including:

- [Quick Start](https://docs.xwidget.dev/getting_started/quick_start/) - installation and setup
- [Fragments](https://docs.xwidget.dev/concepts/fragments/) - XML-based UI components
- [Controllers](https://docs.xwidget.dev/concepts/controllers/) - state and business logic
- [Resources](https://docs.xwidget.dev/concepts/resources/) - strings, colors, numbers,
  booleans, and routes
- [Routing](https://docs.xwidget.dev/concepts/routing/) - route XML, navigation, and
  web URL sync
- [Expression Language](https://docs.xwidget.dev/el/rules/) - operators, functions, and custom logic
- [Server-Driven UI](https://docs.xwidget.dev/concepts/server_driven_ui/) - runtime delivery model
- [Cloud Resources](https://docs.xwidget.dev/runtime/cloud_resources/) - over-the-air UI delivery
- [Analytics](https://docs.xwidget.dev/analytics/overview/) - downloads, renders, errors,
  and transitions
- [Code Generation](https://docs.xwidget.dev/builder/overview/) - inflaters, icons,
  controllers, registry, and schema

## IDE Plugins

- [Flutter XWidget for Android Studio / IntelliJ](https://plugins.jetbrains.com/plugin/25494-flutter-xwidget)
- [Flutter XWidget for VS Code](https://marketplace.visualstudio.com/items?itemName=appfluent.flutter-xwidget)

The plugins add EL syntax highlighting, contextual navigation, component
generation, and hot reload for fragments and resource values.

## License

See [LICENSE](LICENSE) for details.
