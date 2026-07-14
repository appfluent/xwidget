import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:xwidget/src/tags/fragment.dart';
import 'package:xwidget/xwidget.dart';

import '../../fixtures/src/inflaters.g.dart';
import '../testing_utils.dart';

// Regression tests for the 0.7.0 dependenciesScope fix: <fragment> consumes
// its dependenciesScope attribute instead of forwarding it to the child
// fragment as an inherited attribute.
//
// A leaked attribute is not directly observable through the widget tree
// (unknown attribute names are parsed into the child's attribute map and
// never read), so the reserved set is pinned directly, and the pipeline
// test guards that scoped fragments still inflate correctly end to end.
void main() {
  final assetBundle = TestAssetBundle(["test/fixtures/res"]);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await XWidget.initialize(
      resources: LocalResources(
        fragmentsPath: 'test/fixtures/res/fragments',
        assetBundle: assetBundle,
      ),
    );
    registerXWidgetInflaters();
  });

  test("dependenciesScope is a reserved fragment-tag attribute", () {
    // The reserved set is what keeps tag machinery out of the child's
    // inherited attributes. Documented on the fragment reference page:
    // "Any attributes not listed above are forwarded to the child fragment."
    expect(
      FragmentTag.attributeNames,
      containsAll(["dependenciesScope", "for", "name", "visible"]),
    );
  });

  testWidgets("fragment with dependenciesScope inflates and scopes correctly", (tester) async {
    final xml = XmlDocument.parse('''
      <MaterialApp>
        <Scaffold for="home">
          <Column for="body">
            <fragment name="text" dependenciesScope="copy"/>
          </Column>
        </Scaffold>
      </MaterialApp>
    ''');

    final dependencies = Dependencies({"title": "Scoped hello"});
    final testApp = XWidget.inflateFromXmlElement(xml.rootElement, dependencies);
    await tester.pumpWidget(testApp);

    // The child fragment (<Text data="\${title}"/>) renders the parent's
    // value through the copied scope, proving the tag consumed the
    // dependenciesScope attribute without breaking inflation.
    expect(find.text("Scoped hello"), findsOneWidget);
  });
}
