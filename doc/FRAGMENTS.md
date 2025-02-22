# Fragments

Fragments are reusable UI components defined in XML. They allow modular design, making it easy
to structure and maintain UI layouts. Fragments can be used anywhere within an
XWidget-powered application.

## Example Fragment

```xml
<Column xmlns="http://www.appfluent.us/xwidget">
    <Text data="Hello World">
        <TextStyle for="style" fontWeight="bold" color="#262626"/>
    </Text>
    <Text>Welcome to XWidget!</Text>
</Column>
```

Store your fragment files in your assets folder and ensure that all relevant
directories are correctly registered in your pubspec.yaml file.

```yaml
flutter:

  assets:
    # fragments
    - resources/fragments/
```

## Using Fragments in Dart

Fragments can be inflated and added to the widget tree using `XWidget.inflateFragment`:

```dart
Container(
  child: XWidget.inflateFragment("hello_world", Dependencies())
);
```
