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


### Static Functions

These functions are universally accessible within every EL (Expression Language) expression,
providing powerful tools for manipulation and evaluation. They are designed to accept other
expressions as arguments, enabling dynamic and flexible computation. This allows for the creation
of complex expressions by combining multiple functions and expressions, enhancing the overall
functionality and usability of EL in various contexts.

List of static functions:

```dart
num abs(dynamic value);
int ceil(dynamic value);
bool contains(dynamic value, dynamic searchValue);
bool containsKey(Map? map, dynamic searchKey);
bool containsValue(Map? map, dynamic searchValue);
Duration diffDateTime(DateTime left, DateTime right);
bool endsWith(String value, String searchValue);
dynamic eval(String? value);
dynamic first(dynamic value);
int floor(dynamic value);
String formatDateTime(String format, DateTime dateTime);
String? formatDuration(Duration? value, [String precision = "s", DurationFormat? format = defaultDurationFormat]);
bool isBlank(dynamic value);
bool isEmpty(dynamic value);
bool isFalseOrNull(dynamic value);
bool isNotBlank(dynamic value);
bool isNotEmpty(dynamic value);
bool isNotNull(dynamic value);
bool isNull(dynamic value);
bool isTrueOrNull(dynamic value);
dynamic last(dynamic value);
int length(dynamic value);
void logDebug(dynamic message);
bool matches(String value, String regExp);
DateTime now();
DateTime nowInUtc();
double randomDouble();
int randomInt(int max);
String replaceAll(String value, String regex, String replacement);
String replaceFirst(String value, String regex, String replacement, [int startIndex = 0]);
int round(dynamic value);
bool startsWith(String value, String searchValue);
String substring(String value, int start, [int end = -1]);
bool? toBool(dynamic value);
Color? toColor(dynamic value);
DateTime? toDateTime(dynamic value);
int? toDays(dynamic value);
double? toDouble(dynamic value);
Duration? toDuration(dynamic value, [String? intUnit]);
int? toHours(dynamic value);
int? toInt(dynamic value);
int? toMillis(dynamic value);
int? toMinutes(dynamic value);
int? toSeconds(dynamic value);
String? toString(dynamic value);
bool tryToBool(dynamic value);
Color? tryToColor(dynamic value);
DateTime? tryToDateTime(dynamic value);
int? tryToDays(dynamic value);
double? tryToDouble(dynamic value);
Duration? tryToDuration(dynamic value, [String? intUnit]);
int? tryToHours(dynamic value);
int? tryToInt(dynamic value);
int? tryToMillis(dynamic value);
int? tryToMinutes(dynamic value);
int? tryToSeconds(dynamic value);
String? tryToString(dynamic value);
```
Some examples:

```dart
// Absolute Value
${abs(-42)}  // Returns 42

// Rounding a Number
${round(3.7)}  // Returns 4

// Checking if a String Contains a Substring
${contains('Hello, World!', 'World')}  // Returns true

// Getting Current Date and Time
${now()}  // Returns the current date and time

// Formatting a Date
${formatDateTime('yyyy-MM-dd', now())}  // Returns current date in YYYY-MM-DD format

// Checking if a Collection is Empty
${isEmpty(myList)}  // Returns true if myList is empty

// Generating a Random Integer
${randomInt(100)}  // Returns a random integer between 0 and 99

// Replacing a Substring
${replaceAll('I love programming', 'love', 'enjoy')}  // Returns 'I enjoy programming'

// Checking if a String Starts With a Substring
${startsWith('Dart is fun', 'Dart')}  // Returns true

// Converting to Integer
${toInt('123')}  // Returns 123

// Getting the Length of a String
${length('Hello')}  // Returns 5

// Evaluating an Expression
${eval('2 + 2')}  // Returns 4
```

### Instance Functions

In addition to using static functions, you can call instance functions on references and
expressions. This allows you to access and manipulate their properties dynamically.
Instance functions operate on specific instances of a class and can provide more tailored
behavior based on the object's state.

Please note that not all instance functions are supported. If you attempt to call a function
that does not exist on an object, a `NoSuchMethodError` will be thrown. To help you navigate
this limitation, below is a curated list of supported instance functions:

```dart
// alphabetical order
T abs();
int ceil();
int compareTo(T other);
bool contains(E element);
bool containsKey(K key);
bool containsValue(V value);
Set<E> difference(Set<Object> other);
E elementAt(int index);
bool endsWith(String other);
Iterable<MapEntry<K, V>> entries;
E first();
int floor();
int indexOf(E element, [int start = 0]);
Set<E> intersection(Set<Object> other);
bool isEmpty();
bool isEven();
bool isFinite();
bool isInfinite();
bool isNaN();
bool isNegative();
bool isNotEmpty();
bool isOdd();
Iterable<K> keys();
E last();
int lastIndexOf(E element, [int start]);
int length();
Iterable<RegExpMatch> matches(String input);
String padLeft(int width, [String padding = ' ']);
String padRight(int width, [String padding = ' ']);
String replaceAll(Pattern from, String replace);
String replaceFirst(Pattern from, String replace, [int startIndex = 0]);
String replaceRange(int start, int end, String replacement);
int round();
Type runtimeType();
void shuffle([Random? random]);
E single();
List<String> split(Pattern pattern);
bool startsWith(String other, [int index = 0]);
List<E> sublist(int start, [int? end]);
String substring(int start, [int? end]);
double toDouble();
int toInt();
List<E> toList({bool growable = true});
String toLowerCase();
String toRadixString(int radix);
Set<E> toSet();
String toString();
String toUpperCase();
String trim();
String trimLeft();
String trimRight();
int truncate();
Set<E> union(Set<E> other);
Iterable<V> values();
```
Some examples:

```dart
// List Operations
${myList.length()}  // Returns the number of elements in myList

// Map Access
${myMap.containsKey('key1')}  // Checks if 'key1' exists in myMap

// String Manipulation
${(person.firstName + ' ' + person.lastName).toUpperCase()} // Converts expression to uppercase
```

### Custom Functions

Custom functions are user-defined functions that you can add to any `Dependencies` instance.
While they behave similarly to static functions, they are specifically bound to a single
`Dependencies` instance.

It's important to note that custom functions can only accept positional arguments, which
means they cannot use named parameters.

For example:

```dart
// Define a custom function
void greet(String name) {
  return 'Hello, $name!';
}

// Add the custom function to the Dependencies instance
dependencies.setValue("greet", greet);
```

```dart
// Call 'greet' custom function
${greet('Sally')} // Returns: Hello, Sally!
```