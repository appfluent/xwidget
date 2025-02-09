# Expression Language (EL)

XWidget EL is a powerful expression language that enables dynamic evaluation of expressions
within a structured data model. It supports arithmetic, logical, conditional, relational
operators, and functions, allowing for complex calculations and decision-making.

Beyond evaluation, it supports model change notifications and model transformations,
ensuring data-driven applications stay responsive, making it ideal for UI updates, workflow
automation, reactive processing, real-time computation, and dynamic content adaptation.

## Evaluation Rules

Below is the operator precedence and associativity table. Operators are executed according
to their precedence level. If two operators share an operand, the operator with higher precedence
will be executed first. If the operators have the same precedence level, it depends on the
associativity. Both the precedence level and associativity can be seen in the table below.

| Level | Operator                       | Category                                                   | Associativity |
|-------|--------------------------------|------------------------------------------------------------|---------------|
| 11    | identifier<br>'string'<br>123  | Primary Expressions (references, string literals, numbers) | N/A           |
| 10    | `()`<br>`[]`<br>`.`            | Function call, scope, array/member access                  | Right-to-left |
| 9     | `-expr`<br>`!expr`             | Unary Prefix (negation, NOT)                               | Left-to-right |
| 8     | `*`<br>`/`<br>`~/`<br>`%`      | Multiplicative Operators                                   | Left-to-right |
| 7     | `+`<br>`-`                     | Additive Operators                                         | Left-to-right |
| 6     | `<`<br>`>`<br>`<=`<br>`>=`     | Relational Operators                                       | Left-to-right |
| 5     | `==`<br>`!=`                   | Equality Operators                                         | Left-to-right |
| 4     | `&&`                           | Logical AND                                                | Left-to-right |
| 3     | <code>&#124;&#124;</code>      | Logical OR                                                 | Left-to-right |
| 2     | `expr1 ?? expr2`               | Null Coalescing (If null)                                  | Left-to-right |
| 1     | `expr ? expr1 : expr2`         | Conditional (ternary) Operator                             | Right-to-left |


**Important Note:** Strings must be enclosed in single quotes ('). Double quotes (") are not
supported at this time.

## Static Functions

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

```xml
<!-- Absolute Value - Returns 42 -->
<Text data="${abs(-42)}"/>

<!-- Rounding a Number - Returns 4 -->
<Text data="${round(3.7)}"/>

<!-- Checking if a String Contains a Substring - Returns true -->
<if test="${contains('Hello, World!', 'World')}">
  <!-- true condition -->
  <else>
      <!-- optional false condition -->
  </else>
</if>

<!-- Getting Current Date and Time - Returns the current date and time -->
<Text data="${now()}"/>

<!-- Formatting a Date - Returns current date in YYYY-MM-DD format -->
<Text data="${formatDateTime('yyyy-MM-dd', now())}"/>

<!-- Checking if a Collection is Empty - Returns true if myList is empty -->
<if test="${isEmpty(myList)}">
  <!-- true condition -->
  <else>
      <!-- optional false condition -->
  </else>
</if>

<!-- Generating a Random Integer - Returns a random integer between 0 and 99 -->
<Text data="${randomInt(100)}"/>

<!-- Replacing a Substring - Returns 'I love programming' -->
<Text data="${replaceAll('I enjoy programming', 'enjoy', 'love')}"/>

<!-- Checking if a String Starts With a Substring - Returns true -->
<if test="${startsWith('Dart is fun', 'Dart')}">
  <!-- true condition -->
  <else>
      <!-- optional false condition -->
  </else>
</if>

<!-- Converting to Integer - Returns 123 -->
<Text data="${toInt('123')}"/>

<!-- Getting the Length of a String - Returns 5 -->
<Text data="${length('Hello')}"/>

<!-- Evaluating an Expression - Returns 4 -->
<Text data="${eval('2 + 2')}"/>
```

## Instance Functions

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

```xml
<!-- List Operations - Returns the number of elements in myList -->
<Text data="${myList.length()}"/>

<!-- Map Access - checks if 'key1' exists in myMap -->
<if test="${myMap.containsKey('key1')}">
    <!-- true condition -->
    <else>
        <!-- optional false condition -->
    </else>
</if>

<!-- String Manipulation - Concatenation and uppercase conversion -->
<Text data="${(person.firstName + ' ' + person.lastName).toUpperCase()}"/>
```

## Custom Functions

Custom functions are user-defined functions that you can add to any `Dependencies` instance.
While they behave similarly to static functions, they are bound to a single
`Dependencies` instance.

It's important to note that custom functions can only accept positional arguments, which
means they cannot use named parameters.

For example:

```dart
// Define a custom function
void greet(String name) {
  return 'Hello, $name!';
}

// Add the custom function to your Dependencies instance
final dependencies = Dependencies();
dependencies.setValue("greet", greet);
```

```xml
<!--  Call 'greet' custom function -->
<Text data="${greet('Sally')}"/>
```