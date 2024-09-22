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