import 'package:test/test.dart';

import '../../../bin/src/builder/builder.dart';
import '../../../bin/src/builder/inflater_builder.dart';


void main() {
  test('Test InflaterBuilder dependency resolution', () async {
    final config = BuilderConfig();
    config.inflaterConfig.sources.add("xwidget|test/fixtures/src/inflater_spec.dart");
    config.inflaterConfig.target = "build/test.dart";
    config.schemaConfig.template = "xwidget|res/schema_template.xsd";
    config.schemaConfig.target = "build/test.xsd";

    final builder = InflaterBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 2);
  });
}