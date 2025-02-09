# Dependencies

The Dependencies class provides a structured and dynamic way to store and manage data, objects,
and functions used in expression evaluation. At its core, it functions as a flexible key-value map,
allowing nested data access via dot and bracket notation. Reads automatically resolve to null if
a collection does not exist, while writes create the necessary structures. This makes handling
complex data models seamless and intuitive.

Beyond standard mapping behavior, Dependencies supports global data that can be shared across
instances, simplifying cross-component communication. It also integrates with listeners to
enable UI updates when data changes, making it a powerful tool for reactive applications.
Additionally, while Dependencies supports the bracket operator ([]), it maintains ordinary
map behavior, ensuring compatibility with traditional Dart collections.

## Dot/Bracket Notation

Values can be referenced using dot/bracket notation for easy access to nested collections. Nulls
are handled automatically. If the underlying collection does not exist, reads will resolve to
null and writes will create the appropriate collections and store the data.

```dart
// example using setValue
final dependencies = Dependencies();
dependencies.setValue("users[0].name", "John Flutter");
dependencies.setValue("users[0].email", "name@example.com");

print(dependencies.getValue("users"));
```

Or you could use the constructor:

```dart
// example setting values via Dependencies constructor
final dependencies = Dependencies({
  "users[0].name": "John Flutter",
  "users[0].email": "name@example.com"
});

print(dependencies.getValue("users"));
```

Fragment usage example:

```xml
<!-- example iterating over a collection -->
<forEach var="user" items="${users}">
  <Row>
    <Text data="${user.name}"/>
    <Text data="${user.email}"/>
  </Row>
</forEach>
```

**Note:** The Dependencies class supports the bracket operator ([]) directly, i.e.
`dependencies[<key>]`, however, it functions like a standard map, without the advanced features
provided by `getValue` and `setValue`.

## Global Data

Sometimes you just need to access data from multiple parts of an application without a lot
of fuss. Global data are accessible across all ```Dependencies``` instances by adding a
```global``` prefix to the key notation.

```dart
// example setting global values
final dependencies = Dependencies({
  "global.users[0].name": "John Flutter",
  "global.users[0].email": "name@example.com"
});

print(dependencies.getValue("global.users"));
```

Fragment usage example:

```xml
<!-- example iterating over a global collection -->
<forEach var="user" items="${global.users}">
  <Row>
    <Text data="${user.name}"/>
    <Text data="${user.email}"/>
  </Row>
</forEach>
```

## Listen for Changes

```dart
// example listening to changes
final dependencies = Dependencies({
  "users[0].name": "John Flutter",
  "users[0].email": "name@example.com"
});
```

Fragment usage example:

```xml
<!-- example listening to value changes -->
<ValueListener varName="user.email">
    <Text data="${user.email}"/>
</ValueListener>
```