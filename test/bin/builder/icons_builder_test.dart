import 'package:test/test.dart';

import '../../../bin/src/builder/builder.dart';
import '../../../bin/src/builder/icons_builder.dart';


void main() {

  test('Test new icon spec format', () async {
    final config = BuilderConfig();
    await config.loadConfig("xwidget|res/default_config.yaml");
    await config.loadConfig("test/fixtures/res/xwidget_config.yaml");

    final builder = IconsBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 1);
    expect(result.warnings, 0, reason: "Number of warnings");
    expect(result.errors, 0, reason: "Number of errors");
  });
}