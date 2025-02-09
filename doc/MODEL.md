# Model

The Model class serves as the base class for representing structured data in a standardized
format. It provides a flexible and dynamic way to manage properties, offering built-in support
for data transformation, instance management, and null safety. Models can be initialized with
raw data maps and are equipped with utility methods to access and modify properties efficiently.

```dart
class Topic extends Model {

  // getters
  String get key => getValue("key!");
  String get label => getValue("label!");
  String? get rank => getValue("rank");

  // setters
  set rank(String? rank) => setValue("rank", rank);

  Topic(super.data, {super.translation, super.immutable});
}
```

## Null Safety

The Model class ensures null safety through strict property access rules. The ! operator is used
to assert that a value is non-null. When accessing properties using `getValue("property!")`,
it enforces that the value must be present. If the value is missing, an error is thrown,
helping developers catch issues early. Otherwise,

## Instance Management

Instance management ensures that models are consistently instantiated, avoiding duplicate objects
representing the same data. The following factory methods facilitate controlled instance creation.

### `singleInstance`

Ensures that only one instance of a model exists for a given data set. If an instance already
exists, it is returned instead of creating a new one.

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

Creates and retrieves model instances based on a unique key. This ensures that multiple instances
representing the same entity use the same underlying object.

```dart
Models.register<Topic>(Topic.new, const [
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

Checks whether an instance of a model exists for the given data. This is useful when determining
whether to create a new instance or retrieve an existing one.

### `clearInstances`

Removes all stored instances, ensuring that future calls to singleInstance or keyedInstance
generate new objects. This is useful for refreshing models when underlying data changes
significantly.

## Loading Data

When loading data into your models, you may need to first transform its structure or convert its
properties to different types. To do this, use `PropertyTransformer` and `PropertyTranslation`
classes to define the target format and data mappings.

### PropertyTransformer

Each `PropertyTransformer` instance represents a property in your model. It describes a property's
name, data type, and default value. They define the structure of your model. When you register a
model using `Models.register` you can optionally pass a list of `PropertyTransformer`s.
These transformers will automatically be used whenever you create a new model instance.

```dart
// register Content model class
Models.register<Content>(Content.new, const [
  PropertyTransformer<String>("title"),
  PropertyTransformer<String?>("summary"),
  PropertyTransformer<List<Image>>("images"),
]);

// register Image model class
Models.register<Image>(Image.new, const [
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

* Anything that extends `Model`, provided it's registered using with `Models.register`.
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

Models.register<Person>(Person.new, const [
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

Models.register<Content>(Content.new, const [
  PropertyTransformer<String>("title"),
  PropertyTransformer<String?>("summary"),
  PropertyTransformer<Image>("image"),
]);

Models.register<Image>(Image.new, const [
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

Models.register<Content>(Content.new, const [
  PropertyTransformer<String>("title"),
  PropertyTransformer<String?>("summary"),
  PropertyTransformer<List<Image>>("images"),
]);

Models.register<Image>(Image.new, const [
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

Models.register<Content>(Content.new, const [
  PropertyTransformer<String>("title"),
  PropertyTransformer<String?>("summary"),
  PropertyTransformer<List<Image>>("images"),
]);

Models.register<Image>(Image.new, const [
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

When importing data, Model converts source data types into the target's data types using
converter functions. There are preregistered converter functions for `String`, `int`,
`double`, `bool`, `DateTime`, `Duration`, `Color` and `dynamic`. You can also define custom
type converters using the `TypeConverters.register` method. Typically, you should
registration your custom functions in `main()`.

```dart
main() {
  TypeConverters.register<Money>((value) {
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