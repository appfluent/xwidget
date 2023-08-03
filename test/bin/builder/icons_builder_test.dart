import 'package:test/test.dart';

import '../../../bin/src/builder/builder.dart';
import '../../../bin/src/builder/icons_builder.dart';


void main() {

  test('Test new icon spec format', () async {
    final config = BuilderConfig();
    config.iconConfig.sources.add("xwidget|test/fixtures/src/icons_spec.dart");
    config.iconConfig.target = "build/icons_test.g.dart";

    final builder = IconsBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 1);
    expect(result.warnings, 1, reason: "Number of warnings");
    expect(result.errors, 0, reason: "Number of errors");
  });
}