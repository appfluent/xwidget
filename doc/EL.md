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

| Name              | Arguments                                                                     | Returns  | Description | Examples                                                                          |
|-------------------|-------------------------------------------------------------------------------|----------|-------------|-----------------------------------------------------------------------------------|
| abs               | dynamic value                                                                 | num      |             |                                                                                   |
| ceil              | dynamic value                                                                 | int      |             |                                                                                   |
| contains          | dynamic value<br/>dynamic searchValue                                         | bool     |             | `${contains('I love XWidget', 'love'}`<br/>`${contains(dependencyValue, 'hello'}` |
| containsKey       | Map? map<br/>dynamic searchKey                                                | bool     |             |                                                                                   |
| containsValue     | Map? map<br/>dynamic searchValue                                              | bool     |             |                                                                                   |
| diffDateTime      | DateTime left<br/>DateTime right                                              | Duration |             |                                                                                   |
| durationInDays    | Duration value                                                                | int      |             |                                                                                   |
| durationInHours   | Duration value                                                                | int      |             |                                                                                   |
| durationInMinutes | Duration value                                                                | int      |             |                                                                                   |
| durationInSeconds | Duration value                                                                | int      |             |                                                                                   |
| durationInMills   | Duration value                                                                | int      |             |                                                                                   |
| endsWith          | String value<br/>String searchValue                                           | bool     |             |                                                                                   |
| eval              | String? value                                                                 | dynamic  |             |                                                                                   |
| floor             | dynamic value                                                                 | int      |             |                                                                                   |
| formatDateTime    | String format<br/>DateTime dateTime                                           | String   |             |                                                                                   |
| isEmpty           | dynamic value                                                                 | bool     |             |                                                                                   |
| isFalseOrNull     | dynamic value                                                                 | bool     |             |                                                                                   |
| isNotEmpty        | dynamic value                                                                 | bool     |             |                                                                                   |
| isNotNull         | dynamic value                                                                 | bool     |             |                                                                                   |
| isNull            | dynamic value                                                                 | bool     |             |                                                                                   |
| sTrueOrNull       | dynamic value                                                                 | bool     |             |                                                                                   |
| length            | dynamic value                                                                 | length   |             |                                                                                   |
| matches           | String value<br/>String regExp                                                | bool     |             |                                                                                   |
| now               | none                                                                          | DateTime |             |                                                                                   |
| nowInUtc          | none                                                                          | DateTime |             |                                                                                   |
| randomDouble      |                                                                               | double   |             |                                                                                   | 
| randomInt         | int max                                                                       | int      |             |                                                                                   |
| replaceAll        | String value<br/>String regex<br/>String replacement                          | String   |             |                                                                                   |
| replaceFirst      | String value<br/>String regex<br/>String replacement<br/>[int startIndex = 0] | String   |             |                                                                                   |
| round             | dynamic value                                                                 | int      |             |                                                                                   |
| startsWith        | String value<br/>String searchValue                                           | bool     |             |                                                                                   |
| substring         | String value<br/>int start<br/>[int end = -1]                                 | String   |             |                                                                                   |
| toBool            | dynamic value                                                                 | bool     |             |                                                                                   |
| toDateTime        | dynamic value                                                                 | DateTime |             |                                                                                   |
| toDouble          | dynamic value                                                                 | double   |             |                                                                                   |
| toDuration        | String value                                                                  | Duration |             |                                                                                   |
| toInt             | dynamic value                                                                 | int      |             |                                                                                   |
| toString          | dynamic value                                                                 | String   |             |                                                                                   |

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