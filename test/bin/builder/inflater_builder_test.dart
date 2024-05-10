import 'package:test/test.dart';

import '../../../bin/src/builder/builder.dart';
import '../../../bin/src/builder/inflater_builder.dart';


void main() {

  test('Test InflaterBuilder dependency resolution', () async {
    final config = BuilderConfig();
    await config.loadConfig("xwidget|res/default_config.yaml");
    config.inflaterConfig.sources.add("xwidget|test/fixtures/src/inflater_spec.dart");
    config.inflaterConfig.target = "build/test.dart";
    config.schemaConfig.target = "build/test.xsd";

    final builder = InflaterBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 2);
  });

  test('Test new inflater spec format', () async {
    final config = BuilderConfig();
    await config.loadConfig("xwidget|res/default_config.yaml");
    config.inflaterConfig.sources.add("xwidget|test/fixtures/src/inflater_spec.dart");
    config.inflaterConfig.target = "build/inflaters_test.g.dart";
    config.schemaConfig.target = "build/schema_test.xsd";

    final builder = InflaterBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 2);
  });

  test('Test inflater spec generics', () async {
    final config = BuilderConfig();
    await config.loadConfig("xwidget|res/default_config.yaml");
    config.inflaterConfig.sources.add("xwidget|test/fixtures/src/inflater_spec.dart");
    config.inflaterConfig.target = "build/inflaters_test.g.dart";
    config.schemaConfig.target = "build/schema_test.xsd";

    final builder = InflaterBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 2);
  });
}