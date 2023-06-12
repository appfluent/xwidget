import 'package:xwidget/xwidget.dart';

class HomePageController extends Controller {
  var count = 0;

  @override
  void bindDependencies() {
    dependencies["title"] = "XWidget Demo Home Page";
    dependencies["count"] = count;
    dependencies["onPressed"] = onPressed;
  }

  onPressed() {
    // Important: Use setValue to set the value and trigger the onChange listeners.
    // Assignment using the brackets operator [] will overwrite the ValueNotifier created in
    // the <ValueListener> component.
    dependencies.setValue("count", ++count);
  }
}