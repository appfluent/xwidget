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