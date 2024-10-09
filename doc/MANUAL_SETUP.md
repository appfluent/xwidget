# Manual Setup

This Manual Setup guide primarily exists to give you a deeper understanding of how XWidget is
configured. It is recommended that you refer to the [Quick Setup](#quick-setup) guide to
setup a new project.

1. Create an inflater specification file. This is a Dart file that tells XWidget which widgets and
   helper classes you intend on using in your fragments. While this fill can live anywhere
   under the `lib` folder, we recommend placing it under `lib\xwidget` and naming it
   `inflater_spec.dart`. See [Recommended folder structure](#recommended-folder-structure).
   See [Inflaters](#inflaters) for more about inflaters.

    ```dart
    // lib/xwidget/inflater_spec.dart
    import 'package:flutter/material.dart';
    
    const inflaters = [
      Column,   
      Container,
      Text,
      TextStyle, 
    ];
    ```

2. Create a custom configuration file. This is an XML document that configures the inputs and
   outputs of XWidget's code generator. By default, XWidget looks for a file named
   `xwidget_config.yaml` in the project's root folder. Make sure that `sources` contains the
   location of the inflater spec you created in step #2. See [Configuration](#configuration)
   for more.

    ```yaml
    # xwidget_config.yaml
    inflaters:
       sources: [ "lib/xwidget/inflater_spec.dart" ]
    ```
3. Generate inflaters and fragment schema. By default, all generated Dart files are written to
   `lib/xwidget/generated`. The schema file is written to the project root as `xwidget_schema.g.xsd`.
   See [Code Generation](#code-generation) for more.

    ```shell
    $ dart run xwidget:generate 
    ```

4. Register the generated schema file `xwidget_scheme.g.xsd` with your IDE under the namespace
   `http://www.appfluent.us/xwidget`. This will provide validation, code completion, and tooltip
   documentation while editing your fragments.

5. Register the generated components in your application's main method. You'll need to import
   XWidget and the generated code.

   ```dart
   import 'package:xwidget/xwidget.dart';
   import 'xwidget/generated/inflaters.g.dart';
   
   main() async {
      WidgetsFlutterBinding.ensureInitialized();
    
      // load resources i.e. fragments, values, etc.
      await Resources.instance.loadResources("resources");
    
      // register XWidget components
      registerXWidgetInflaters();
      ...
   }
   ```

6. Modify your project's `pubspec.yaml` and add `resources/fragments/` and `resources/values/` 
   to `assets`. There's no need to add each individual fragment; however, if you use fragment
   folders, you'll need to add each folder here. See [Resources](#resources) for more.

    ```yaml
    flutter:
      assets:
        - resources/fragments/
        - resources/values/
    ```

7. Create your UI fragment. By default, XWidget looks for fragments under `resources/fragments`.
   Fragments are XML documents that are "inflated" at runtime. See [Fragments](#fragments) for more.

    ```XML
    <?xml version="1.0"?>
   
   <!-- resources/fragments/hello_world.xml -->
    <Column xmlns="http://www.appfluent.us/xwidget">
        <Text data="Hello World">
            <TextStyle for="style" fontWeight="bold" color="#262626"/>
        </Text>
        <Text>Welcome to XWidget!</Text>
    </Column>
    ```

8. Inflate your fragment. Where ever you want to render your fragment, simply call
   *XWidget.inflateFragment(...)* with the name of your fragment and `Dependencies` object. See
   [Dependencies](#dependencies) for more.

   ```dart
   // Example 1
   Container(
     child: XWidget.inflateFragment("hello_world", Dependencies())
   )
   ```

   ```dart
   // Example 2
   @override
   Widget build(BuildContext context) {
     return XWidget.inflateFragment("hello_world", Dependencies()); 
   }
   ```

Don't forget to install the [Flutter XWidget](https://plugins.jetbrains.com/plugin/25494-flutter-xwidget)
plugin for Android Studio. It provides EL syntax highlighting, contextual navigation, component
generation and more.