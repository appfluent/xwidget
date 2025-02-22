# Best Practices

### Do use fragment folders

Using fragment folders helps keep your project organized by grouping related UI components
together. Fragments should be stored in appropriately named folders to improve
maintainability and scalability. Ensure that each fragment is self-contained and
follows a consistent naming convention.

### Don't specify unused widgets

Only include references to widgets and icons in your specification files 
(`inflater_spec.dart`, `icon_spec.dart`) if you intend to use them in your application. 
This is because all referenced elements will be bundled with your app, regardless of
whether they are used, and will not be removed by Flutter’s tree shaking optimization.

### Do check-in generated files into source control

Since the generated code is used dynamically and is highly dependent on the installed version
of Flutter, we believe it is best to check in XWidget’s generated files to ensure build
stability. This prevents inconsistencies that may arise from differences in Flutter versions
or code generation tools across development environments. By committing these files, we
ensure that all team members and CI/CD pipelines work with a consistent, tested version of
the generated code, reducing the risk of unexpected issues caused by regeneration discrepancies. 

### Instantiate a new Dependencies object for each page

Each page should have its own Dependencies object to ensure proper dependency isolation.
This prevents unintended side effects from shared dependencies and maintains modularity.

```dart
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
          body: XWidget.inflateFragment("profile/settings", Dependencies())
      );
    }));
```

### Prefer automatic scoping of Dependencies within Fragments

Automatic scoping of dependencies ensures that each component receives the correct dependencies
based on its usage. This can reduce unexpected side effects when dependencies are 
scoped incorrectly. Use the `dependenciesScope` attribute on tags that support it i.e.
[<builder>](#builder), [<callback>](#callback), [<forEach>](#foreach), [<forLoop>](#forloop),
[<fragment>](#fragment). Possible values are `new`, `copy`, `inherit` - leave empty for
auto scoping.

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

A well-structured project enhances maintainability and code clarity. Below is a recommended
folder structure for organizing XWidget-based projects:

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

Following this structure ensures a clean separation of concerns, making the project easier
to navigate and manage.
