# Controllers

XWidget allows you to define and register custom controllers to manage business logic and
dynamic behaviors within your fragments. Controllers act as the bridge between your
fragments and the underlying data or event handling mechanisms.

## Creating Controllers

Define controllers in `lib/xwidget/controllers/`:

```dart
import 'package:xwidget/xwidget.dart';

class CounterController extends Controller {
  var count = 0;
  
  @override
  void bindDependencies() {
    dependencies.setValue("count", count);
    dependencies.setValue("increment", increment);
  }

  void increment() {
    dependencies.setValue("count", ++count);
  }
}
```

## Generating Controller Bindings

To generate controller bindings, run the following command:

```shell
$ dart run xwidget_builder:generate --only controllers
```

This command processes your project’s controller definitions and generates the necessary
Dart files to integrate them into your application.

## Registering Controllers in Your Application

Once the controllers have been generated, you need to register them during your app’s
initialization. Update your main function as follows:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ...
  // register XWidget components
  registerXWidgetInflaters();
  registerXWidgetControllers();
  ...
}
```

## Using Controllers in Your Fragments

Bind controllers to UI elements:

```xml
<Controller name="CounterController">
    <!-- listen for changes to 'count' and update children -->
    <ValueListener varName="count">
        <Text data="${toString(count)}"/>
    </ValueListener>
    <Button onPressed="${increment}">
        <Text>Increment</Text>
    </Button>
</Controller>
```