import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import '../../lib/xwidget.dart';

void main() {
  test('Test map inside list', () {
    final deps = Dependencies();
    deps.setValue("users[0].name", "chris");
    expect(deps.getValue("users"), [{"name":"chris"}] );
  });

  test('Test bracket operator with dot notation', () {
    final deps = Dependencies();
    deps["user.id"] = 123;
    deps["user.name"] = "chris";
    expect(deps["user"], null);
    expect(deps["user.id"], 123);
  });

  test('Test map create from individual calls', () {
    final deps = Dependencies();
    deps.setValue("user.id", 123);
    deps.setValue("user.name", "chris");
    expect(deps.getValue("user"), {"id":123, "name":"chris"});
  });

  test('Test global map create from individual calls', () {
    final deps = Dependencies();
    deps.setValue("global.user.id", 123);
    deps.setValue("global.user.name", "chris");
    expect(deps.getValue("global.user"), {"id":123, "name":"chris"});
  });

  testWidgets('Test getting global map value thru change listener', (tester) async {
    final deps = Dependencies();
    deps.setValue("global.user.id", 123);
    deps.setValue("global.user.name", "chris");

    final element = XmlElement(XmlName("ValueListener"));
    final valueListener = ValueListener(element: element, dependencies: deps, varName: "global.user");
    await tester.pumpWidget(valueListener);
    expect(deps.getValue("global.user"), {"id":123, "name":"chris"});
  });

  testWidgets('Test global map value notifier creation', (tester) async {
    final deps = Dependencies();
    deps.setValue("global.user.id", 123);
    deps.setValue("global.user.name", "chris");

    final element = XmlElement(XmlName("ValueListener"));
    final valueListener = ValueListener(element: element, dependencies: deps, varName: "global.user");
    await tester.pumpWidget(valueListener);
    expect(deps["global.user"].runtimeType.toString(), "ModelValueNotifier");
  });

  test('Test formatted data', () {
    final deps = Dependencies();
    deps.setValue("user.id", 123);
    deps.setValue("user.name", "chris");
    expect(deps.toString(), {"id":123, "name":"chris"});
  });

}