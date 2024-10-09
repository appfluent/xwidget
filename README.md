<!-- This file includes generated content. Run 'dart run tool/markdown -f' to update this file. -->

<!-- #include doc/HEADER.md -->
<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget/main/doc/assets/xwidget_logo_full.png"
        alt="XWidget Logo"
        height="100"
    />
</p>

<p align="center">
    <img src="https://raw.githubusercontent.com/appfluent/xwidget/main/doc/assets/code_animation.gif"
        alt="Code Animation"
        style="max-width:800px; width:100%; height:auto;"
    />
</p>

<p data-control-type="install" role="button" tabindex="0" style="
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    flex-direction: row;
    width: 245px;
    height: 48px;
    background: #333 url(https://plugins.jetbrains.com/static/versions/32235/button-install.png) no-repeat;
    background-size: contain;
    border-radius: 25px;
    box-shadow: 0 1px 2px 0 rgba(0, 0, 0, .25);
    cursor: pointer;
    transition: background-color;
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;">
    <a href="https://plugins.jetbrains.com/plugin/25494-flutter-xwidget" rel="noopener noreferrer" target="_blank" style="
        color: #fff;
        text-decoration: none;
        font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen, Ubuntu, Cantarell, Droid Sans, Helvetica Neue, Arial, sans-serif;
        font-size: 16px;
        font-weight: 400;
        line-height: 24px;
        letter-spacing: .0015em;">
        Android Studio Plugin
    </a>
</p>

### *Note: This document is very much still a work in progress.*
<!-- // end of #include -->

<!-- #include doc/INTRO.md -->
# What is XWidget?

XWidget is a not-so-opinionated library for building dynamic UIs in Flutter using an expressive,
XML based markup language.

That was a mouth full, so let's break it down. "Not-so-opinionated" means that you're not forced to
use XWidget in any particular way. You can use as much or as little of the framework as you want -
whatever makes sense for your project. There are, however, a few [Best Practices](#best-practices)
that you should follow to help keep your code organized and your final build size down to a minimum.

An XWidget UI is defined in XML and parsed at runtime. You have access to all the Flutter widgets
and classes you are used to working with, including widgets from 3rd party libraries and even your
own custom widgets. This is achieved through code generation. You specify which widgets you want to
use and XWidget will generate the appropriate classes and functions and make them available as XML
elements. You'll have access to all of the Widgets' constructor arguments as element attribute just
as if you were writing Dart code. You'll even have code completion and access to Widgets'
documentation in tooltips, if provided by the author, when you register the generated XML schema
with your IDE.

For example:

```xml
<Column crossAxisAlignment="start">
    <Text data="Hello World">
        <TextStyle for="style" fontWeight="bold" color="#262626"/>
    </Text>
    <Text>Welcome to XWidget!</Text>
</Column>
```

**Important:** Only specify widgets that you actually use in your UI. Specifying unused widgets and
helper classes in your configuration will bloat your app size. This is because code is generated for
every component you specify and thus neutralizes Flutter's tree-shaking.
<!-- // end of #include -->

<!-- #include doc/TOC.md -->
# Table of Contents

1. [Quick Start](#quick-start)
2. [Manual Setup](#manual-setup)
3. [Example](#example)
4. [Configuration](#configuration)
5. [Code Generation](#code-generation)
6. [Inflaters](#inflaters)
7. [Dependencies](#dependencies)
8. [Model](#model)
    - [Null Safety](#null-safety)
    - [Instance Management](#instance-management)
    - [Loading Data](#loading-data)
9. [Fragments](#fragments)
10. [Controllers](#controllers)
11. [Expression Language (EL)](#expression-language-el)
    - [Operators](#operators)
    - [Static Functions](#static-functions)
    - [Instance Functions](#instance-functions)
    - [Custom Functions](#custom-functions)
12. [Resources](#resources)
    - [Strings](#strings)
    - [Integers](#integers)
    - [Doubles](#doubles)
    - [Booleans](#booleans)
    - [Colors](#colors)
    - [Fragments](#fragments-1)
13. [Components](#components)
    - [Flutter](#flutter)
    - [Third Party](#third-party)
    - [Built-In](#built-in)
        - [```<Controller>```](#controller)
        - [```<DynamicBuilder>```](#dynamicbuilder)
        - [```<EventListener>```](#eventlistener)
        - [```<List>```](#list)
        - [```<Map>```](#map)
        - [```<MapEntry>```](#mapentry)
        - [```<MediaQuery>```](#mediaquery)
        - [```<ValueListener>```](#valuelistener)
    - [Custom](#custom)
14. [Tags](#tags)
    - [```<builder>```](#builder)
    - [```<callback>```](#callback)
    - [```<debug>```](#debug)
    - [```<forEach>```](#foreach)
    - [```<forLoop>```](#forloop)
    - [```<fragment>```](#fragment)
    - [```<if>/<else>```](#ifelse)
    - [```<var>```](#var)
15. [Best Practices](#best-practices)
16. [Tips and Tricks](#tips-and-tricks)
17. [Trouble Shooting](#trouble-shooting)
    - [The generated inflater code has errors](#the-generated-inflater-code-has-errors)
    - [Hot reload/restart clears dependency values](#hot-reloadrestart-clears-dependency-values)
18. [FAQ](#faq)
19. [Roadmap](#roadmap)
    - [0.0.x Releases (2023)](#00x-releases-2023)
    - [0.x Releases (2024)](#0x-releases-2024)
    - [1.0.0 Release (mid 2024)](#100-release-mid-2024)
20. [Known Issues](#known-issues)
<!-- // end of #include -->

<!-- #include doc/QUICK_START.md -->
# Quick Start

This Quick Start guide will help you get up and running with XWidget in just a few minutes. For a
more comprehensive description of the various components and features, please see the sections
below.

1. Install XWidget using the following command:

    ```shell
    $ flutter pub add xwidget
    ```

2. Initialize your project by running:

    ```shell
    $ dart run xwidget:init --new-app
    ```
   
   This will create and configure all the components required for a simple XWidget application.
   It will overwrite `main.dart`, `pubscpec.yaml` and existing XWidget specifications,
   configurations, colors and string values. If you don't want to overwrite these files, run the
   following non-destructive initialization command:

    ```shell
    $ dart run xwidget:init
    ```
   
   The non-destructive command is intended for advanced users that want to add XWidget to an
   existing project. For those users, follow the [Manual Setup](#manual-setup) guide starting
   with step #4. Everyone else should continue to step #3 in this guide.

3. Register the generated schema file `xwidget_scheme.g.xsd` with your IDE under the namespace
   `http://www.appfluent.us/xwidget`. This will provide validation, code completion, and tooltip
   documentation while editing your fragments.

4. To register additional Flutter components, simply modify `lib/xwidget/inflater_spec.dart`
   and run:

    ```shell
    $ dart run xwidget:generate --only inflaters
    ```

5. Install the [Flutter XWidget](https://plugins.jetbrains.com/plugin/25494-flutter-xwidget)
   plugin for Android Studio. This step is optional, but recommended. It provide EL syntax
   highlighting, contextual navigation, component generation and more.

   See [Inflaters](#inflaters), [Components](#components) and [Fragments](#fragments) for
   more information.
<!-- // end of #include -->

<!-- #include doc/MANUAL_SETUP.md -->
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
<!-- // end of #include -->


<!-- #include doc/EXAMPLE.md -->
# Example

Please see the [example](https://github.com/appfluent/xwidget/tree/main/example) folder of this
package. It contains an XWidget version of Flutter's classic starter app. It only scratches the
surface of XWidget's capabilities.

**Please Note:** The inflaters in the example were generated with Flutter 3.19, which means that if
you're using an older version Flutter, you'll need to regenerate the inflaters using the 
following command:

```shell
$ dart run xwidget:generate --only inflaters 
```

Here are some apps using XWidget:
- [MoneyMagnate (Google Play)](https://play.google.com/store/apps/details?id=us.appfluent.moneymagnate.moneymagnate)
<!-- // end of #include -->

<!-- #include doc/CONFIGURATION.md -->
# Configuration

By default, XWidget's code generator looks for a custom configuration file named `xwidget_config.yaml`
in the project root. This custom configuration is layered on top of XWidget's own default configuration
which handles most of the configuration burden. See `package:xwidget/res/default_config.yaml` for
details.

Since the default config does most of the heavy lifting, the typical config can be relatively simple
like this example:

```yaml
# custom config - xwidget_config.yaml
inflaters:
  imports: [
    "dart:ui",
    "package:flutter/foundation.dart",
    "package:flutter/gestures.dart",
  ]
  sources: [ "lib/xwidget/inflater_spec.dart" ]
  includes: [ "lib/xwidget/inflater_spec_includes.dart" ]

icons:
  sources: [ "lib/xwidget/icon_spec.dart" ]
```

There are four top-level mappings that configure each of the four generated
outputs: `inflaters`, `schema`, `controllers`, and `icons`.

### Inflaters Configuration

```yaml
# Responsible for configuring inputs and outputs to generate inflaters.
inflaters:

  # The file path to save the generated code. The output contains all inflater classes
  # and a library function to to register them. The default value can be overwritten.
  # 
  # DEFAULT: "lib/xwidget/generated/inflaters.g.dart"
  target:

  # A list of additional imports to include in the generated output. Sometimes the code
  # generator can't determine all the required imports. This happens because of a
  # current limitation in dealing with default values for constructor arguments. This
  # option allows manual configuration when needed. Custom imports are appended to
  # XWidget's default list.
  #
  # DEFAULT: [ "package:xwidget/xwidget.dart" ]
  imports: [ ]

  # List of list inflater specification source files. Specifications tell XWidget which 
  # objects to create inflaters for.
  #
  # DEFAULT: none
  sources: [ ]

  # DEFAULT none
  includes: [ ]

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  constructor_exclusions: [ "<class_name | * for any>:<constructor_argument_name>", ]

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  constructor_arg_defaults:
    "<class_name | * for any>:<constructor_argument_name>": "<value>"

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  constructor_arg_parsers:

    # EXAMPLES:
    # - "double": "double.parse(value)"
    # - "Alignment": "parseAlignment(value)"
    # - "*:width": "parseWidth(value)"
    "<constructor_argument_type | * for any>(: <constructor_argument_name>)": "<parser_function_call>"
```

```dart
// example inflater specification.
import 'package:flutter/material.dart';

// Best Practice: Keep declarations in alphabetical order. It makes it much easier
// to quickly determine what has been added and what is missing.

const inflaters = [
  AppBar,
  Center,
  Column,
  FloatingActionButton,
  Icon,
  MaterialApp,
  Scaffold,
  Text,
  TextStyle,
  ThemeData,
];
```

### Schema Configuration

```yaml
# Responsible for configuring inputs and outputs to generate the inflater schema.
# Register the generated schema with your IDE to get code completion and documentation
# while editing fragments. 
schema:

  # DEFAULT: "xwidget_schema.g.xsd"
  target:

  # DEFAULT: "xwidget|res/schema_template.xsd"   
  template:

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  types:
    # EXAMPLES
    # - "bool": "boolAttributeType"
    # - "BoxFit": "BoxFitAttributeType"
    "<constructor_argument_type>": "<schema_defined_type>"

  # DEFAULT: See 'package:xwidget/res/default_config.yaml'
  attribute_exclusions: [

    # EXAMPLES:
    # - "*:child"                       
    "<class_name | * for any>:<constructor_argument_name | * for any>",
  ]
```

### Controllers Configuration

```yaml
controllers:

  # DEFAULT: "lib/xwidget/generated/controllers.g.dart" 
  target:

  # DEFAULT: [ "package:xwidget/xwidget.dart" ]
  imports: [ ]

  # DEFAULT: [ "lib/xwidget/controllers/**.dart" ]
  sources: [ ]
```

### Icons Configuration

```yaml
icons:

  # DEFAULT: "lib/xwidget/generated/icons.g.dart"
  target:

  # DEFAULT: [ "package:xwidget/xwidget.dart" ]
  imports: [ ]

  # List of list icon specification source files. Specifications tell XWidget
  # which icons to register.
  #
  # DEFAULT: none
  sources: [ ]
```

```dart
// example icon specification
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// List icons individually to reduce app size.
const icons = [
  Icons.add,
  Icons.delete,
];

// Not recommended, but you can also include the entire icon set by simply
// referencing the enclosing class. This assumes that each icon is declared
// as a static field of type IconData.
const iconSets = [
  CupertinoIcons,
];
```
<!-- // end of #include -->

<!-- #include doc/CODE_GENERATION.md -->
# Code Generation

*Add documentation here.*

```shell
$ dart run xwidget:generate 
```

```shell
$ dart run xwidget:generate --help 
```

```shell
$ dart run xwidget:generate --config "my_config.yaml" 
```

```shell
$ dart run xwidget:generate --only inflaters,controllers,icons 
```

```shell
$ dart run xwidget:generate --allow-deprecated 
```
<!-- // end of #include -->

<!-- #include doc/INFLATERS.md -->
# Inflaters

Inflaters are the heart of XWidget. They are responsible for building the UI at runtime by parsing
attribute values and constructing the components defined in fragments. In other words, they are the
primary mechanism by which your XML markup gets transformed from this:

```XML
<Container height="50" width="50">
    <Text data="Hello world!"/>
</Container>
```

into the widget tree represented by this:

```Dart
Container({
  height: 50,
  width: 50,
  child: Text("Hello world!")
});
```

A good analogy is the relationship between a recipe, a chef and a meal. The recipe describes how to
create the meal. It lists the ingredients, preparation instructions, etc. The chef does all the work
described in the recipe. The meal is the finished product. Your XML markup is the recipe, the
inflaters are the chefs in the kitchen, and the instantiated widget tree is the meal, which is then
served to the end user.

Inflaters are generated from a user (a developer using XWidget) defined specification written in
Dart. The specification is very simple and its sole purpose is to tell the code generator which
widgets to generate code for. Once the code has been generated, the widgets can be referenced in
your markup.

You can create inflaters for basically anything that is a class and has a public constructor. For
example, [BoxDecoration](https://api.flutter.dev/flutter/painting/BoxDecoration-class.html)
and [TextStyle](https://api.flutter.dev/flutter/painting/TextStyle-class.html) are not widgets,
they're helper classes that style widgets.

```Dart
// a very simple inflater specification
import 'package:flutter/material.dart';

const inflaters = [
  Container,
  Text,
  TextStyle,
];
```

You can add as many components as required by your application; however, you should only specify
components that you actually need. Specifying unused components in your configuration will
unnecessarily increase your app size. This is because code is generated for every component you
specify and thus neutralizes Flutter's tree-shaking.

There are four built-in inflaters: ```<Controller>```, ```<DynamicBuilder>```, ```<ListOf>```, and
```ValueListener```. You can read more about them in the [Custom Inflaters] section.

### Parsers

Each `Inflater` has a `parseAttribute` method that is responsible for parsing attribute values.
The parsed values are then passed to the `inflate` method during object construction.

XWidget already knows how to parse most of the common attribute types such as `bool`, `int`,
`double`, `Alignment`, `Color`, `Curve`, `Duration`, and many more. Please see
[default_config.yaml](https://github.com/appfluent/xwidget/blob/main/res/default_config.yaml)
for a complete list. It's also capable of dynamically parsing any enum type without any additional
configuration.

You can also create your own parsers, if XWidget's built-in capabilities are not enough. The
built-in parsers are good examples of how to construct an attribute parser i.e. `Alignment` parser:

```dart
// Alignment parser
Alignment? parseAlignment(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case 'topLeft': return Alignment.topLeft;
      case 'topCenter': return Alignment.topCenter;
      case 'topRight': return Alignment.topRight;
      case 'centerLeft': return Alignment.centerLeft;
      case 'center': return Alignment.center;
      case 'centerRight': return Alignment.centerRight;
      case 'bottomLeft': return Alignment.bottomLeft;
      case 'bottomCenter': return Alignment.bottomCenter;
      case 'bottomRight': return Alignment.bottomRight;
      default: throw Exception("Invalid alignment value: $value");
    }
  }
  return null;
}
```

Once you've created your parser, you'll need to register it inside your XWidget configuration file.
Please see `constructor_arg_parsers:` under [Inflaters Configuration](#inflaters-configuration)
for details.

Next, you'll need to make sure you import the dart file that contains your parser. Please see
`imports:` under [Inflaters Configuration](#inflaters-configuration) for details.

### XML Schema

*Add documentation here.*

### Code Completion & Tooltip Documentation

*Add documentation here.*
<!-- // end of #include -->

<!-- #include doc/DEPENDENCIES.md -->
# Dependencies

In the context of XWidget, dependencies are data, objects, and functions needed to render a fragment.
The ```Dependencies``` object, at its core, is just a map of dependencies as defined above. Every
*inflate* method call requires a ```Dependencies``` object. It can be a new instance or one that was
received from a previous *inflate* method invocation.

## Scoping

### `copy`
### `inherit`
### `new`
### Auto Scope

## Features

```Dependencies``` objects have a few characteristics that make them a little more interesting than plain
old maps.

1. Values can be referenced using dot/bracket notation for easy access to nested collections. Nulls
   are handled automatically. If the underlying collection does not exist, reads will resolve to
   null and writes will create the appropriate collections and store the data.<br><br>

   Dart example:
   ```dart
   // example using setValue
   final dependencies = Dependencies();
   dependencies.setValue("users[0].name", "John Flutter");
   dependencies.setValue("users[0].email", "name@example.com");
   
   print(dependencies.getValue("users[0].name"));
   print(dependencies.getValue("users[0].email"));
   ```
   Or you could use the constructor:
   ```dart
   // example setting values via Dependencies constructor
   final dependencies = Dependencies({
     "users[0].name": "John Flutter",
     "users[0].email": "name@example.com"
   });
   
   print(dependencies.getValue("users[0].name"));
   print(dependencies.getValue("users[0].email"));
   ```
   Markup usage example:
   ```xml
   <!-- example iterating over a collection -->
   <forEach var="user" items="${users}">
     <Row>
       <Text data="${user.name}"/>
       <Text data="${user.email}"/>
     </Row>
   </forEach>
   ```
2. Supports global data. Sometimes you just need to access data from multiple parts of an
   application without a lot of fuss. Global data are accessible across all ```Dependencies```
   instances by adding a ```global``` prefix to the key notation.<br><br>

   Dart example:
    ```dart
   // example setting global values
    final dependencies = Dependencies({
      "global.users[0].name": "John Flutter",
      "global.users[0].email": "name@example.com"
    });
   
    print(dependencies.getValue("global.users[0].name"));
    print(dependencies.getValue("global.users[0].email"));
    ```

   Markup usage example:
   ```xml
   <!-- example iterating over a global collection -->
   <forEach var="user" items="${global.users}">
     <Row>
       <Text data="${user.name}"/>
       <Text data="${user.email}"/>
     </Row>
   </forEach>
   ```
3. When combined with the ```ValueListener``` custom widget, the UI can listen for data changes and
   update itself. In the following example, if the user's email address changes, then the ```Text```
   widget is rebuilt.

   ```xml
   <!-- example listening to value changes -->
   <ValueListener varName="user.email">
       <Text data="${user.email}"/>
   </ValueListener>
   ```

**Note:** ```Dependencies``` also supports the bracket operator []; however, it behaves like an
ordinary map.
<!-- // end of #include -->

<!-- #include doc/MODEL.md -->
# Model

*Add documentation here.*

```dart
class Topic extends Model {

  // getters
  String get key => getValue("key!");
  String get label => getValue("label!");
  String get color => getValue("color!");
  String? get rank => getValue("rank");

  // setters
  set rank(String? rank) => setValue("rank", rank);

  Topic(super.data, {super.translation, super.immutable});
}
```

## Null Safety

*Add documentation here.*

### `!`

### `?`

## Instance Management

*Add documentation here.*

### `singleInstance`

*Add documentation here.*

```dart
class Topic extends Model {
  Topic._(super.data, {super.translation, super.immutable});

  factory Topic(
    Map<String, dynamic> data, {
    PropertyTranslation? translation,
    bool? immutable,
  }) {
    return Model.singleInstance<Topic>(
      factory: Topic._,
      data: data,
      tranlsation: translation,
      immutable: immutable
    );
  }
}
```

### `keyedInstance`

*Add documentation here.*

```dart
XWidget.registerModel<Topic>(Topic.new, const [
  PropertyTransformer<String>("key", isKey: true),
  PropertyTransformer<String?>("name"),
]);

class Topic extends Model {
  Topic._(super.data, {super.translation, super.immutable});

  factory Topic(
    Map<String, dynamic> data, {
    PropertyTranslation? translation,
    bool? immutable,
  }) {
    return Model.keyedInstance<Topic>(
      factory: Topic._,
      data: data,
      tranlsation: translation,
      immutable: immutable
    );
  }
}
```

### `hasInstance`

*Add documentation here.*

### `clearInstances`

*Add documentation here.*

## Loading Data

When loading data into your models, you may need to first transform its structure or convert its
properties to different types. To do this, use `PropertyTransformer` and `PropertyTranslation` 
classes to define the target format and data mappings.

### PropertyTransformer

Each `PropertyTransformer` instance represents a property in your model. It describes a property's
name, data type, and default value. They define the structure of your model. When you register a
model using `XWidget.registerModel()` you can optionally pass a list of `PropertyTransformer`s.
These transformers will automatically be used whenever you create a new model instance.

```dart
// register Content model class
XWidget.registerModel<Content>(Content.new, const [
  PropertyTransformer<String>("title"),
  PropertyTransformer<String?>("summary"),
  PropertyTransformer<List<Image>>("images"),
]);

// register Image model class
XWidget.registerModel<Image>(Image.new, const [
    PropertyTransformer<String>("url"),
    PropertyTransformer<String?>("caption"),
    PropertyTransformer<bool>("active", defaultValue: true),
]);

class Content extends Model {
  Content(super.data, {super.translation, super.immutable}); 
}

class Image extends Model {
  Image(super.data, {super.translation, super.immutable});
}
```

The following property types are natively supported:

* Anything that extends `Model`, provided it's registered using with `XWidget.registerModel()`.
* The Basic types `String`, `int`, `double`, and `bool`.
* The types `Color`, `DateTime`, and `Duration`.
* The collections `List`, `Set` and `Map`. Prefer using a subclass of `Model` class over `Map`, 
  if possible.
* `List<List>` is not well supported at the moment
* Custom types are supported by registering transform functions.
  See [Transform Functions](transform-functions)

### PropertyTranslation

The `PropertyTranslation` class enables you to map a source data structure to a target data
structure, making it particularly useful when the source data structure doesn't align with your
model's structure. This class is also beneficial when your model needs to load data from various
sources, each with its own distinct data structure. Simply specify a source/target property pair
for each property that needs to be mapped. If a target property is not explicitly mapped, it
will default to using the same name for the source property.

```dart
// translate 'firstName' to 'first' and 'lastName' to 'last' translation. Since all other source
// property names match the target property names, they will be imported without translation.

XWidget.registerModel<Person>(Person.new, const [
  PropertyTransformer<String>("first"),
  PropertyTransformer<String>("last"),
  PropertyTransformer<bool>("employee"),
  PropertyTransformer<int>("age"),
]);

class Person extends Model {
  Person(super.data, {super.translation, super.immutable});
}

final person = Person({
  "firstName": "Mike",
  "lastName": "Jones",
  "employee": "true",
  "age": "25"
}, translation: PropertyTranslation({
  "firstName": "first",
  "lastName": "last"
}));

expect(person, {
  "first": "Mike",
  "last": "Jones",
  "employee": true,
  "age": 25
});
```

```dart
// this example shows how to load data into a nested model, 'Image'.

XWidget.registerModel<Content>(Content.new, const [
  PropertyTransformer<String>("title"),
  PropertyTransformer<String?>("summary"),
  PropertyTransformer<Image>("image"),
]);

XWidget.registerModel<Image>(Image.new, const [
  PropertyTransformer<String>("url"),
  PropertyTransformer<String?>("caption"),
]);

class Content extends Model {
  Content(super.data, {super.translation, super.immutable});
}

class Image extends Model {
  Image(super.data, {super.translation, super.immutable});
}

final content = Content({
  "title": "Hello World",
  "summary": "Basic App",
  "imageUrl": "https://www.example.com/image.jpg",
  "imageCaption": "Sunset",
}, translation: PropertyTranslation({
  "imageUrl": "image.url",
  "imageCaption": "image.caption",
}));

expect(content, {
  'title': 'Hello World',
  'summary': 'Basic App',
  'image': {'url': 'https://www.example.com/image.jpg', 'caption': 'Sunset'}
});
```

```dart
// this example shows how to add multiple models to a List.

XWidget.registerModel<Content>(Content.new, const [
  PropertyTransformer<String>("title"),
  PropertyTransformer<String?>("summary"),
  PropertyTransformer<List<Image>>("images"),
]);

XWidget.registerModel<Image>(Image.new, const [
  PropertyTransformer<String>("url"),
  PropertyTransformer<String?>("caption"),
]);

class Content extends Model {
  Content(super.data, {super.translation, super.immutable});
}

class Image extends Model {
  Image(super.data, {super.translation, super.immutable});
}

final content = Content({
  "title": "Hello World",
  "summary": "Basic App",
  "myImages": [
    {"url": "https://www.example.com/image1.jpg", "caption": "#1"},
    {"url": "https://www.example.com/image2.jpg", "caption": "#2"},
    {"url": "https://www.example.com/image3.jpg", "caption": "#3"},
  ]
}, translation: PropertyTranslation({
  "myImages": "images",
}));

expect(content, {
  'title': 'Hello World',
  'summary': 'Basic App',
  'images': [
    {'url': 'https://www.example.com/image1.jpg', 'caption': '#1'},
    {'url': 'https://www.example.com/image2.jpg', 'caption': '#2'},
    {"url": "https://www.example.com/image3.jpg", "caption": "#3"},
  ]
});
```

```dart
// this example shows how to add multiple unindexed models to a list.

XWidget.registerModel<Content>(Content.new, const [
  PropertyTransformer<String>("title"),
  PropertyTransformer<String?>("summary"),
  PropertyTransformer<List<Image>>("images"),
]);

XWidget.registerModel<Image>(Image.new, const [
  PropertyTransformer<String>("url"),
  PropertyTransformer<String?>("caption"),
]);

class Content extends Model {
  Content(super.data, {super.translation, super.immutable});
}

class Image extends Model {
  Image(super.data, {super.translation, super.immutable});
}

final model = TestModel({
  "title": "Hello World",
  "summary": "Basic App",
  "primaryImageUrl": "https://www.example.com/image.jpg",
  "secondaryImageUrl": "https://www.example.com/image2.jpg",
  "secondaryImageCaption": "Secondary",
}, translation: PropertyTranslation({
  "primaryImageUrl": "images.url",
  "primaryImageCaption": "images.caption",
  "secondaryImageUrl": "images.url",
  "secondaryImageCaption": "images.caption",
}));

expect(model, {
  'title': 'Hello World',
  'summary': 'Basic App',
  'images': [
    {'url': 'https://www.example.com/image.jpg'},
    {'url': 'https://www.example.com/image2.jpg', 'caption': 'Secondary'}
  ]
});
```

### Type Converters

When importing model data, XWidget converts source data types into the target's data types using
converter functions. There are preregistered converter functions for `String`, `int`,
`double`, `bool`, `DateTime`, `Duration`, `Color` and `dynamic`. You can also define custom
type converters using the `XWidget.registerTypeConverter` method. Typically, you should 
registration your custom functions in `main()`.

```dart
main() {
  XWidget.registerTypeConverter<Money>((value) {
    if (value is Money) {
      return value;
    } else if (value is String) {
      return Money.parse(value, isoCode: 'USD');
    } else if (value is int) {
      return Money.fromInt(value, isoCode: 'USD');
    } else {
      throw Exception("Unable to convert value of type ${value.runtimeType} to 'Money'");
    }
  });
}
```
<!-- // end of #include -->

<!-- #include doc/FRAGMENTS.md -->
# Fragments

*Add documentation here.*
<!-- // end of #include -->

<!-- #include doc/CONTROLLERS.md -->
# Controllers

*Add documentation here.*
<!-- // end of #include -->

<!-- #include doc/EL.md -->
# Expression Language (EL)

*Add documentation here.*

### Operators

Below is the operator precedence and associativity table. Operators are executed according
to their precedence level. If two operators share an operand, the operator with higher precedence
will be executed first. If the operators have the same precedence level, it depends on the
associativity. Both the precedence level and associativity can be seen in the table below.

| Level | Operator                   | Category                                  | Associativity |
|-------|----------------------------|-------------------------------------------|---------------|
| 10    | `()`<br>`[]`<br>`.`        | Function call, scope, array/member access |               |
| 9     | `-expr`<br>`!expr`         | Unary Prefix                              |               |
| 8     | `*`<br>`/`<br>`~/`<br>`%`  | Multiplicative                            | Left-to-right |
| 7     | `+`<br>`-`                 | Additive                                  | Left-to-right |
| 6     | `<`<br>`>`<br>`<=`<br>`>=` | Relational                                |               |
| 5     | `==`<br>`!=`               | Equality                                  |               |
| 4     | `&&`                       | Logical AND                               | Left-to-right |
| 3     | <code>&#124;&#124;</code>  | Logical OR                                | Left-to-right |
| 2     | `expr1 ?? expr2`           | If null                                   | Left-to-right |
| 1     | `expr ? expr1 : expr2`     | Conditional (ternary)                     | Right-to-left |


### Static Functions

These functions are universally accessible within every EL (Expression Language) expression,
providing powerful tools for manipulation and evaluation. They are designed to accept other
expressions as arguments, enabling dynamic and flexible computation. This allows for the creation
of complex expressions by combining multiple functions and expressions, enhancing the overall
functionality and usability of EL in various contexts.

List of static functions:

```dart
num abs(dynamic value);
int ceil(dynamic value);
bool contains(dynamic value, dynamic searchValue);
bool containsKey(Map? map, dynamic searchKey);
bool containsValue(Map? map, dynamic searchValue);
Duration diffDateTime(DateTime left, DateTime right);
bool endsWith(String value, String searchValue);
dynamic eval(String? value);
dynamic first(dynamic value);
int floor(dynamic value);
String formatDateTime(String format, DateTime dateTime);
String? formatDuration(Duration? value, [String precision = "s", DurationFormat? format = defaultDurationFormat]);
bool isBlank(dynamic value);
bool isEmpty(dynamic value);
bool isFalseOrNull(dynamic value);
bool isNotBlank(dynamic value);
bool isNotEmpty(dynamic value);
bool isNotNull(dynamic value);
bool isNull(dynamic value);
bool isTrueOrNull(dynamic value);
dynamic last(dynamic value);
int length(dynamic value);
void logDebug(dynamic message);
bool matches(String value, String regExp);
DateTime now();
DateTime nowInUtc();
double randomDouble();
int randomInt(int max);
String replaceAll(String value, String regex, String replacement);
String replaceFirst(String value, String regex, String replacement, [int startIndex = 0]);
int round(dynamic value);
bool startsWith(String value, String searchValue);
String substring(String value, int start, [int end = -1]);
bool? toBool(dynamic value);
Color? toColor(dynamic value);
DateTime? toDateTime(dynamic value);
int? toDays(dynamic value);
double? toDouble(dynamic value);
Duration? toDuration(dynamic value, [String? intUnit]);
int? toHours(dynamic value);
int? toInt(dynamic value);
int? toMillis(dynamic value);
int? toMinutes(dynamic value);
int? toSeconds(dynamic value);
String? toString(dynamic value);
bool tryToBool(dynamic value);
Color? tryToColor(dynamic value);
DateTime? tryToDateTime(dynamic value);
int? tryToDays(dynamic value);
double? tryToDouble(dynamic value);
Duration? tryToDuration(dynamic value, [String? intUnit]);
int? tryToHours(dynamic value);
int? tryToInt(dynamic value);
int? tryToMillis(dynamic value);
int? tryToMinutes(dynamic value);
int? tryToSeconds(dynamic value);
String? tryToString(dynamic value);
```
Some examples:

```dart
// Absolute Value
${abs(-42)}  // Returns 42

// Rounding a Number
${round(3.7)}  // Returns 4

// Checking if a String Contains a Substring
${contains('Hello, World!', 'World')}  // Returns true

// Getting Current Date and Time
${now()}  // Returns the current date and time

// Formatting a Date
${formatDateTime('yyyy-MM-dd', now())}  // Returns current date in YYYY-MM-DD format

// Checking if a Collection is Empty
${isEmpty(myList)}  // Returns true if myList is empty

// Generating a Random Integer
${randomInt(100)}  // Returns a random integer between 0 and 99

// Replacing a Substring
${replaceAll('I love programming', 'love', 'enjoy')}  // Returns 'I enjoy programming'

// Checking if a String Starts With a Substring
${startsWith('Dart is fun', 'Dart')}  // Returns true

// Converting to Integer
${toInt('123')}  // Returns 123

// Getting the Length of a String
${length('Hello')}  // Returns 5

// Evaluating an Expression
${eval('2 + 2')}  // Returns 4
```

### Instance Functions

In addition to using static functions, you can call instance functions on references and
expressions. This allows you to access and manipulate their properties dynamically.
Instance functions operate on specific instances of a class and can provide more tailored
behavior based on the object's state.

Please note that not all instance functions are supported. If you attempt to call a function
that does not exist on an object, a `NoSuchMethodError` will be thrown. To help you navigate
this limitation, below is a curated list of supported instance functions:

```dart
// alphabetical order
T abs();
int ceil();
int compareTo(T other);
bool contains(E element);
bool containsKey(K key);
bool containsValue(V value);
Set<E> difference(Set<Object> other);
E elementAt(int index);
bool endsWith(String other);
Iterable<MapEntry<K, V>> entries;
E first();
int floor();
int indexOf(E element, [int start = 0]);
Set<E> intersection(Set<Object> other);
bool isEmpty();
bool isEven();
bool isFinite();
bool isInfinite();
bool isNaN();
bool isNegative();
bool isNotEmpty();
bool isOdd();
Iterable<K> keys();
E last();
int lastIndexOf(E element, [int start]);
int length();
Iterable<RegExpMatch> matches(String input);
String padLeft(int width, [String padding = ' ']);
String padRight(int width, [String padding = ' ']);
String replaceAll(Pattern from, String replace);
String replaceFirst(Pattern from, String replace, [int startIndex = 0]);
String replaceRange(int start, int end, String replacement);
int round();
Type runtimeType();
void shuffle([Random? random]);
E single();
List<String> split(Pattern pattern);
bool startsWith(String other, [int index = 0]);
List<E> sublist(int start, [int? end]);
String substring(int start, [int? end]);
double toDouble();
int toInt();
List<E> toList({bool growable = true});
String toLowerCase();
String toRadixString(int radix);
Set<E> toSet();
String toString();
String toUpperCase();
String trim();
String trimLeft();
String trimRight();
int truncate();
Set<E> union(Set<E> other);
Iterable<V> values();
```
Some examples:

```dart
// List Operations
${myList.length()}  // Returns the number of elements in myList

// Map Access
${myMap.containsKey('key1')}  // Checks if 'key1' exists in myMap

// String Manipulation
${(person.firstName + ' ' + person.lastName).toUpperCase()} // Converts expression to uppercase
```

### Custom Functions

Custom functions are user-defined functions that you can add to any `Dependencies` instance.
While they behave similarly to static functions, they are specifically bound to a single
`Dependencies` instance.

It's important to note that custom functions can only accept positional arguments, which
means they cannot use named parameters.

For example:

```dart
// Define a custom function
void greet(String name) {
  return 'Hello, $name!';
}

// Add the custom function to the Dependencies instance
dependencies.setValue("greet", greet);
```

```dart
// Call 'greet' custom function
${greet('Sally')} // Returns: Hello, Sally!
```
<!-- // end of #include -->

<!-- #include doc/RESOURCES.md -->
# Resources

*Add documentation here.*

### Strings

*Add documentation here.*

### Integers

*Add documentation here.*

### Doubles

*Add documentation here.*

### Booleans

*Add documentation here.*

### Colors

*Add documentation here.*

### Fragments

*Add documentation here.*
<!-- // end of #include -->

<!-- #include doc/COMPONENTS.md -->
# Components

*Add documentation here.*

## Flutter

*Add documentation here.*

## Third Party

*Add documentation here.*

## Built-In

*Add documentation here.*

### ```<Controller>```

*Add documentation here.*

### ```<DynamicBuilder>```

*Add documentation here.*

### ```<EventListener>```

*Add documentation here.*

### ```<List>```

*Add documentation here.*

### ```<Map>```

*Add documentation here.*

### ```<MapEntry>```

*Add documentation here.*

### ```<MediaQuery>```

*Add documentation here.*

### ```<ValueListener>```

*Add documentation here.*

## Custom

*Add documentation here.*
<!-- // end of #include -->

<!-- #include doc/TAGS.md -->
# Tags

Tags are XML elements that do not, themselves, add components to the widget tree. They provide
common structure and control elements for constructing the UI such as conditionals, iteration,
fragment inclusion, etc. They are always represented in lowercase to distinguish them from inflaters.

## ```<builder>```

A tag that wraps its children in a builder function.

This tag is extremely useful when the parent requires a builder function, such as
[PageView.builder](https://api.flutter.dev/flutter/widgets/PageView/PageView.builder.html).
Use `vars`, `multiChild`, and `nullable` attributes to define the builder function signature.
When the builder function executes, the values of named arguments defined in `vars` are stored
as dependencies in the current `Dependencies` instance. The values of placeholder arguments (_) are
simply ignored. The `BuildContext` is never stored as a dependency, even if explicitly named,
because it would cause a memory leak.

| Attribute         | Description                                                                                                                                | Required | Default |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`.                          | no       | auto    |
| for               | The name of the parent's attribute that will be assigned the builder function.                                                             | yes      | null    |
| multiChild        | Whether the builder function should return an array of widgets or a single widget.                                                         | no       | false   |
| nullable          | Whether the builder function can return null.                                                                                              | no       | false   |
| vars              | A comma separated list of builder function arguments. Values of named arguments are stored as dependencies. Supports up to five arguments. | no       | null    |

Example usage:
```xml
<PageView.builder>
    <builder for="itemBuilder" vars="_,index" nullable="true">
        <Container>
            <Text data="${index}"/>
        </Container>
    </builder>
</PageView.builder>
```

## ```<callback>```

This tag allows you to bind an event handler with custom arguments. If you don't need to pass any
arguments, then just bind the handler using EL, like so: `<TextButton onPressed="${onPressed}"/>`.
This is sufficient in most cases.

The `callback` tag creates an event handler function for you and executes the `action` when the
event is triggered. `action` is an EL expression that is evaluated at the time of the event. Do not
enclose the expression in curly braces `${...}`, otherwise it will be evaluated immediately upon
creation instead of when the event is fired.

If the handler function defines arguments in its signature, you must declare those arguments using
the `vars` attribute. This attribute takes a comma separated list of argument names. When the
handler is triggered, argument values are added to `Dependencies` using the specified name as the
key, and can be referenced in the `action` EL expression, if needed. They're also accessible
anywhere else that instance of `Dependencies` is available. If you don't need the values, then use
and underscore (_) in place of the name. Doing so will ignore the values and they won't be added to
`Dependencies` e.g. `...vars="_,index"...`. `BuildContext` is never added to `Dependencies` even
when named, because this would cause a memory leak.

| Attribute         | Description                                                                                                                                | Required | Default |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|----------|---------|
| action            | The El expression to evaluate when the event handler is triggered.                                                                         | yes      | null    |
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`.                          | no       | auto    |
| for               | The name of the parent's attribute that will be assigned the event handler.                                                                | yes      | null    |
| returnVar         | The storage destination within `Dependencies` for the return value of `action`.                                                            | no       | null    |
| vars              | A comma separated list of handler function arguments. Values of named arguments are stored as dependencies. Supports up to five arguments. | no       | null    |

```xml
<TextButton>
    <callback for="onPressed" action="doSomething('Hello World')"/>
    <Text>Press Me</Text>
</TextButton>

```

## ```<debug>```

A simple tag that logs a debug message

| Attribute | Description         | Required | Default |
|-----------|---------------------|----------|---------|
| message   | The message to log. | yes      | null    |

```xml
<debug message="Hello world!"/>
```

## ```<forEach>```

*Add documentation here.*

| Attribute         | Description                                                                                                       | Required | Default |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|---------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | `copy`  |
| indexVar          |                                                                                                                   | no       | null    |
| items             |                                                                                                                   | yes      | null    |
| multiChild        |                                                                                                                   | no       | null    |
| nullable          |                                                                                                                   | no       | null    |
| var               |                                                                                                                   | yes      | null    |

```xml
<forEach var="user" items="${users}">

</forEach>
```

## ```<forLoop>```

*Add documentation here.*

| Attribute         | Description                                                                                                       | Required | Default |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|---------|
| begin             |                                                                                                                   | no       | 0       |
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | `copy`  |
| end               |                                                                                                                   | no       | 0       |
| step              |                                                                                                                   | no       | 1       |
| var               |                                                                                                                   | yes      | null    |

```xml
<forLoop var="index" begin="1" end="5">

</forLoop>
```

## ```<fragment>```

A tag that renders a UI fragment

| Attribute         | Description                                                                                                       | Required | Default |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|---------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | auto    |
| for               | The name of the parent's attribute that will be assigned the fragment's output.                                   | no       | null    |
| name              | The `Resources` name of the fragment.                                                                             | yes      | null    |

```xml
<AppBar>
    <fragment for="leading" name="profile/icon"/>
</AppBar>
```

## ```<if>```/```<else>```

*Add documentation here.*

| Attribute | Description                                        | Required | Default |
|-----------|----------------------------------------------------|----------|---------|
| test      | EL expression tht must evaluate to a `bool` value. | yes      | null    |


```xml
<if test="${}">
    <fragnent name=""/>
    <else>
        <fragnent name=""/>
    </else>
</if>
```

## ```<var>```

*Add documentation here.*

| Attribute | Description | Required | Default |
|-----------|-------------|----------|---------|
| name      |             | yes      | null    |
| value     |             | yes      | null    |

```xml
<var name="" value=""/>
```
<!-- // end of #include -->

<!-- #include doc/BEST_PRACTICES.md -->
# Best Practices

### Do use fragment folders

*Add documentation here.*

### Don't specify unused widgets

*Add documentation here.*

### Do check-in generated files into source control

*Add documentation here.*

### Instantiate a new Dependencies object for each page

```dart
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
          body: XWidget.inflateFragment("profile/settings", Dependencies())
      );
    }));
```

*Add documentation here.*

### Prefer automatic scoping of Dependencies

*Add documentation here.*

### Do extend Model and create constructors with explicit properties

While it's convenient to use the `Model` class as-is, extending the `Model` class and creating a
constructor with all your model's properties defined as parameters is a more robust approach.
This method ensures that all data is validated before it enters your model, helping prevent
errors down the road.

```dart
// easy, but error prone
final profile = Model({
  "username": "mike.smith",
  "email": "mike.smith@example.com",
  "name": "Mike Smith"
});
```

```dart
// more verbose, but more stable and fewer potential errors
final profile = Profile(
  username: "mike.smith",
  email: "mike.smith@example.com",
  name: "Mike Smith"
);

class Profile extends Model {
  String get username => getValue("username");
  String get email => getValue("email");
  String? get name => getValue("name");
  DateTime? get lastLogin => getValue("lastLogin");
  
  Profile({
    required String username,
    required String email,
    String? name,
    DateTime? lastLogin,
  }) :super({
    "username": username,
    "email": email,
    "name": name,
    "lastLogin": lastLogin,
  });
}
```

If you need to load data from a Map structure, then override `propertyTransformers` getter
and add an `import` factory constructor. See [Model -> Loading Data](#loading-data) for more
information.

Note: In the near future, XWidget will have the ability to generate most of the required code for you.

```dart
XWidget.registerModel<Profile>(Profile.import, const [
    PropertyTransformer<String>("username"),
    PropertyTransformer<String>("email"),
    PropertyTransformer<String?>("name"),
    PropertyTransformer<DateTime?>("lastLogin"),
]);

class Profile extends Model {
  String get username => getValue("username");
  String get email => getValue("email");
  String? get name => getValue("name");
  DateTime? get lastLogin => getValue("lastLogin");
  
  Profile({
    required String username,
    required String email,
    String? name,
    DateTime? lastLogin,
  }) :super({
    "username": username,
    "email": email,
    "name": name,
    "lastLogin": lastLogin,
  });

  Profile.import(super.data, {super.translation, super.immutable});
}
```

### Recommended folder structure

*Add documentation here.*

```markdown
project
├── lib
│   └── xwidget          # holds all specification files used in code generation
│       ├── controllers  # holds all custom controllers
│       └── generated    # holds all generated .g.dart files
└── resources
    ├── fragments  # holds all fragments
    └── values     # holds all resource values i.e strings.xml, bools.xml, colors.xml, etc.
```
<!-- // end of #include -->

<!-- #include doc/TIPS_TRICKS.md -->
# Tips and Tricks

## Regenerate inflaters after upgrading Flutter

*Add documentation here.*

## Use controllers to create reusable components

*Add documentation here.*

## Specify generic types with literals when your model is mutable.

When listening for changes using `<ValueListener>` or `listenForChanges`, XWidget wraps a
`ModelValueNotifier` around the data that is being listening to. Therefore, it is important
that model collections be type agnostic i.e. `dynamic` or `Object?`. For example:

```dart
// don't do this - no types
final model = Model({
  "users": {
    "user1": { "email": "@", "phone": "0" },
    "user2": { "email": "@", "phone": "0" }
  }
});
// throws exception
final user1Notifier = model.listenForChanges("users.user1", null, null);
```
This throws `type 'ModelValueNotifier' is not a subtype of type 'Map<String, String>' of 'value'`.
To fix this, explicitly specify the Map's `key` and `value` types:

```dart
// this is ok - explicitly typed maps
final model = Model({
  "users": <String, dynamic>{
    "user1": <String, dynamic>{ "email": "@", "phone": "0" },
    "user2": <String, dynamic>{ "email": "@", "phone": "0" }
  }
});
// this now works.
// NOTE: You typically wouldn't call `listenForChanges' directly. You would use
// <ValueListener> in your fragment instead.
final user1Notifier = model.listenForChanges("users.user1", null, null);
```
<!-- // end of #include -->

<!-- #include doc/TROUBLE_SHOOTING.md -->
# Trouble Shooting

## The generated inflater code has errors

The most common cause of errors in generated inflater code is due to constructor argument defaults
referencing undefined variables. If the referenced variable type is not a primitive, then XWidget
can't infer how to generate the default value and will fallback to using the variable reference.

The solution is to manually set the default value for the constructor argument in XWidget's
configuration file under the `constructor_arg_defaults:` key.

```yaml
# xwidget_config.yaml
inflaters:  
  constructor_arg_defaults:
    # example defaults
    "WidgetSpan:alignment": "PlaceholderAlignment.middle",
    "*:colorBlendMode": "BlendMode.srcIn"
```

See [Inflaters Configuration](#inflaters-configuration) for details.

## Hot Reload/Restart clears dependency values

Hot reload loads code changes into the VM and re-builds the widget tree, preserving the app state;
it doesn't rerun `main()` or `initState()`.

Make sure that you're not binding dependencies in `main()`, `initState()` or any other
initialization function such as `Controller.initialize()`. Dependencies should be bound in the
build function of your widget. If you are using a Controller, simply override the
`bindDependencies()` method with your implementation and XWidget will handle the rest.
<!-- // end of #include -->

<!-- #include doc/FAQ.md -->
# FAQ

## 1. What problems does XWidget solve?

The first and most obvious answer is that it gives applications the flexibility to create and modify
its UI at runtime. An app might want to give its users the ability to download a different
look-and-feel or create dynamic forms all without a redeployment. You're only limited by the
existing functionality of your custom controllers, since they're static Dart code.

It provides better separation between business and presentation layers out of the box. Sometimes
developers struggle with the best way to separate these concerns. XWidget inherently addresses
these problems in an uncomplicated way with fragments and controllers.

This may just be our opinion, but building views in code just feels clunky. We find it more
enjoyable to write our UIs using markup - it feels more natural and it's certainly a lot easier to
read. The experience should only get better as we improve IDE integration.

## I don't need dynamic UIs, why should I still use XWidget?

While not all apps require dynamic user interfaces, incorporating XWidget can still yield
substantial benefits. XWidget enhances code quality by promoting organization and readability,
contributing to overall code improvement.

Code readability is a fundamental aspect of quality code for any software project. Readable
code is much easier to debug, maintain, and understand. XWidget's strong separation between
presentation logic and layout leads to better organized code. Its XML based markup language
for building layouts is vastly easier to read and modify than the default, code centric approach
offered by the Flutter framework. Additionally, XWidget can manage your static string, boolean,
numeric, and color resources, so that values are never hardcoded directly into your layouts or
anywhere else. Please read the [Fragments](#fragments), [Controllers](#controllers), and
[Resources](#resources) sections above.
<!-- // end of #include -->

<!-- #include doc/ROADMAP.md -->
# Roadmap

The primary focus right now is documentation, critical bug fixes, more documentation, minor
improvements, and oh, even more documentation. The implementation is already fairly stable, but
lacks test coverage. Once the documentation is complete, we'll bump the minor version and
concentrate on testing.

## 0.0.x Releases (2023)

* Write README and API documentation
* Critical bug fixes
* Minor improvements

## 0.x Releases (2024)

* Write unit, widget, UI, and performance tests
* Critical and major bug fixes
* Refine and add documentation as needed

## 1.0.0 Release (mid 2024)

* Stable release
<!-- // end of #include -->

<!-- #include doc/KNOWN_ISSUES.md -->
# Known Issues

None at the moment :smile:
<!-- // end of #include -->