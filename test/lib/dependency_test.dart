import 'package:flutter_test/flutter_test.dart';
import 'package:xwidget/xwidget.dart';

void main() {
  test('Creates nested collections', () {
    final deps = Dependencies();

    deps.setValue("users[0].name", "chris");
    final name = deps.getValue("users[0].name");
    print(deps);
  });
}