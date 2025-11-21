import 'package:xwidget/xwidget.dart';

class AppController extends Controller {
  var count = 0;

  @override
  void bindDependencies() {
    dependencies.setValue("count", count);
    dependencies.setValue("onPressed", onPressed);
  }

  void onPressed() {
    // Important: Use setValue to set the value and trigger the onChange
    // listeners. Assignment using the brackets operator [] will overwrite
    // the ValueNotifier created in the <ValueListener> component.
    dependencies.setValue("count", ++count);
  }
}