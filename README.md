### *Note: This document is very much still a work in progress.* 

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
elements. You'll have access to all of the Widgets' constructor arguments as element properties just
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

# Quick Start

This Quick Start guide will help you get up and running with XWidget in just a few minutes. For a
more comprehensive description of the various components and features, please see the sections
below.

1. Install XWidget using the following command:

    ```shell
    $ flutter pub add xwidget 
    ```
   
2. Create an inflater specification file. This is a Dart file that tells XWidget which widgets and
   helper classes you're planning on using in your fragments. See [Inflaters](#inflaters) for more.

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
   
3. Create a custom configuration file. This is an XML document that configures the inputs and 
   outputs of XWidget's code generator. By default, XWidget looks for a file named 
   `xwidget_config.yaml` in the project's root folder. Make sure that `sources` contains the
   location of the inflater spec you created in step #2. See [Configuration](#configuration)
   for more.

    ```yaml
    # xwidget_config.yaml
    inflaters:
       sources: [ "lib/xwidget/inflater_spec.dart" ]
    ```
4. Generate inflaters and fragment schema. By default, all generated Dart files are written to 
   `lib/xwidget/generated`. The schema file is written to the project root as `xwidget_schema.g.xsd`.
   See [Code Generation](#code-generation) for more. 

    ```shell
    $ dart run xwidget:generate 
    ```
   
5. Register the generated schema file with your IDE under the namespace 
   `http://www.appfluent.us/xwidget`. This will provide validation, code completion, and tooltip
   documentation while editing your fragments.<br><br>

6. Register the generated components in your application's main method. You'll need to import
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
   
7. Modify your project's `pubspec.yaml` and add `resources/fragments/` to `assets`. There's no need
   to add each individual fragment; however, if you use fragment folders, you'll need to add each
   folder here. See [Resources](#resources) for more.

    ```yaml
    flutter:
      assets:
        - resources/fragments/
    ```

8. Create your UI fragment. By default, XWidget looks for fragments under `resources/fragments`.
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
   
9. Inflate your fragment. Where ever you want to render your fragment, simply call 
   *XWidget.inflateFragment(...)* with the name of your fragment and `Dependencies`. See
   [Dependencies](#dependencies) for more.

   ```dart
   return Container(
     child: XWidget.inflateFragment("hello_world", Dependencies())
   )
   ```

# Example

Please see the [example](https://github.com/appfluent/xwidget/tree/main/example) folder of this
package. It contains an XWidget version of Flutter's classic starter app. It only scratches the
surface of XWidget's capabilities.

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
# while editing UI markup. 
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

*Add documentation here.*

### Custom Inflaters

*Add documentation here.*

### XML Schema

*Add documentation here.*

### Code Completion & Tooltip Documentation

*Add documentation here.*

# Dependencies

In the context of XWidget, dependencies are data, objects, and functions needed to render a fragment.
The ```Dependencies``` object, at its core, is just a map of dependencies as defined above. Every
*inflate* method call requires a ```Dependencies``` object. It can be a new instance or one that was
received from a previous *inflate* method invocation.

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

# Fragments

*Add documentation here.*

# Controllers

*Add documentation here.*

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


### Built-In Functions

| Name              | Arguments                                     | Returns  | Description | Examples                                                                          |
|-------------------|-----------------------------------------------|----------|-------------|-----------------------------------------------------------------------------------|
| contains          | dynamic value<br/>dynamic searchValue         | bool     |             | `${contains('I love XWidget', 'love'}`<br/>`${contains(dependencyValue, 'hello'}` |
| containsKey       | Map? map<br/>dynamic searchKey                | bool     |             |                                                                                   |
| containsValue     | Map? map<br/>dynamic searchValue              | bool     |             |                                                                                   |
| diffDateTime      | DateTime left<br/>DateTime right              | Duration |             |                                                                                   |
| durationInDays    | Duration value                                | int      |             |                                                                                   |
| durationInHours   | Duration value                                | int      |             |                                                                                   |
| durationInMinutes | Duration value                                | int      |             |                                                                                   |
| durationInSeconds | Duration value                                | int      |             |                                                                                   |
| durationInMills   | Duration value                                | int      |             |                                                                                   |
| endsWith          | String value<br/>String searchValue           | bool     |             |                                                                                   |
| eval              | String? value                                 | dynamic  |             |                                                                                   |
| formatDateTime    | String format<br/>DateTime dateTime           | String   |             |                                                                                   |
| isEmpty           | dynamic value                                 | bool     |             |                                                                                   |
| isNotEmpty        | dynamic value                                 | bool     |             |                                                                                   |
| isNotNull         | dynamic value                                 | bool     |             |                                                                                   |
| isNull            | dynamic value                                 | bool     |             |                                                                                   |
| length            | dynamic value                                 | length   |             |                                                                                   |
| matches           | String value<br/>String regExp                | bool     |             |                                                                                   |
| now               | none                                          | DateTime |             |                                                                                   |
| nowInUtc          | none                                          | DateTime |             |                                                                                   |
| startsWith        | String value<br/>String searchValue           | bool     |             |                                                                                   |
| substring         | String value<br/>int start<br/>[int end = -1] | String   |             |                                                                                   |
| toDateTime        | dynamic value                                 | DateTime |             |                                                                                   |
| toDuration        | String value                                  | Duration |             |                                                                                   |
| toString          | dynamic value                                 | String   |             |                                                                                   |

### Custom Functions

Custom functions are functions that you define and add to your `Dependencies`. They behave like
built-in functions except that they are bound to a single `Dependencies` instance. Custom functions
can have up to 10 required and/or optional arguments.

For example:

```dart
dependencies["addNumbers"] = addNumbers

int addNumbers(int n1, [int n2 = 0, int n3 = 0, int n4 = 0, int n5 = 0]) {
   return n1 + n2 + n3 + n4 + n5;
}
```

Example usage:
```xml
<Text data="${addNumbers(2,8,4}"/>
```
 
# Resources

*Add documentation here.*

### Strings

*Add documentation here.*

### Ints

*Add documentation here.*

### Doubles

*Add documentation here.*

### Bools

*Add documentation here.*

### Colors

*Add documentation here.*

### Fragments

*Add documentation here.*

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

| Attribute         | Description                                                                                                                                | Required | Default   |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`.                          | no       | `inherit` |
| for               | The name of the parent's attribute that will be assigned the builder function.                                                             | yes      | null      |
| multiChild        | Whether the builder function should return an array of widgets or a single widget.                                                         | no       | false     |
| nullable          | Whether the builder function can return null.                                                                                              | no       | false     |
| vars              | A comma separated list of builder function arguments. Values of named arguments are stored as dependencies. Supports up to five arguments. | no       | null      |

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

| Attribute         | Description                                                                                                                                | Required | Default   |
|-------------------|--------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------|
| action            | The El expression to evaluate when the event handler is triggered.                                                                         | yes      | null      |
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`.                          | no       | `inherit` |
| for               | The name of the parent's attribute that will be assigned the event handler.                                                                | yes      | null      |
| returnVar         | The storage destination within `Dependencies` for the return value of `action`.                                                            | no       | null      |
| vars              | A comma separated list of handler function arguments. Values of named arguments are stored as dependencies. Supports up to five arguments. | no       | null      |

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

| Attribute         | Description                                                                                                       | Required | Default   |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|-----------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | `inherit` |
| indexVar          |                                                                                                                   | no       | null      |
| items             |                                                                                                                   | yes      | null      |
| multiChild        |                                                                                                                   | no       | null      |
| nullable          |                                                                                                                   | no       | null      |
| var               |                                                                                                                   | yes      | null      |

```xml
<forEach var="user" items="${users}">
   
</forEach>
```

## ```<forLoop>```

*Add documentation here.*

| Attribute         | Description                                                                                                       | Required | Default   |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|-----------|
| begin             |                                                                                                                   | no       | 0         |
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | `inherit` |
| end               |                                                                                                                   | no       | 0         |
| step              |                                                                                                                   | no       | 1         |
| var               |                                                                                                                   | yes      | null      |

```xml
<forLoop var="index" begin="1" end="5">
   
</forLoop>
```

## ```<fragment>```

A tag that renders a UI fragment

| Attribute         | Description                                                                                                       | Required | Default   |
|-------------------|-------------------------------------------------------------------------------------------------------------------|----------|-----------|
| dependenciesScope | Defines the method for passing Dependencies to immediate children. Valid values are `new`, `copy`, and `inherit`. | no       | `inherit` |
| for               | The name of the parent's attribute that will be assigned the fragment's output.                                   | no       | null      |
| name              | The `Resources` name of the fragment.                                                                             | yes      | null      |

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

# Logging

*Add documentation here.*

# Best Practices

### Do use fragment folders

*Add documentation here.*

### Don't specify unused widgets

*Add documentation here.*

### Do check-in generated files into source control

*Add documentation here.*

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

# Tips and Tricks

### Regenerate inflaters after upgrading Flutter

*Add documentation here.*

### Use controllers to create reusable components

*Add documentation here.*

# FAQ

### 1. What problems does XWidget solve?

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

# Roadmap

The primary focus right now is documentation, critical bug fixes, more documentation, minor
improvements, and oh, even more documentation. The implementation is already fairly stable, but 
lacks test coverage. Once the documentation is complete, we'll bump the minor version and
concentrate on testing.

### 0.0.x Releases (2023)

* Write README and API documentation
* Critical bug fixes
* Minor improvements

### 0.x Releases (2024)

* Write unit, widget, UI, and performance tests
* Critical and major bug fixes
* Refine and add documentation as needed

### 1.0.0 Release (mid 2024)

* Stable release

# Known Issues

None at the moment :)