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