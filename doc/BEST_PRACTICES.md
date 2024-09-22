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
