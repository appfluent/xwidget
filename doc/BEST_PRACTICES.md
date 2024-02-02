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
