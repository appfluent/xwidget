import 'package:test/test.dart';

import '../../../bin/src/builders/builder.dart';
import '../../../bin/src/builders/inflaters.dart';


void main() {

  test('Test InflaterBuilder dependency resolution', () async {
    final config = BuilderConfig();
    await config.loadConfig("xwidget|res/default_config.yaml");
    await config.loadConfig("test/fixtures/res/xwidget_config.yaml");

    final builder = InflaterBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 2);
  });

  test('Test new inflater spec format', () async {
    final config = BuilderConfig();
    await config.loadConfig("xwidget|res/default_config.yaml");
    await config.loadConfig("test/fixtures/res/xwidget_config.yaml");

    final builder = InflaterBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 2);
  });

  test('Test inflater spec generics', () async {
    final config = BuilderConfig();
    await config.loadConfig("xwidget|res/default_config.yaml");
    await config.loadConfig("test/fixtures/res/xwidget_config.yaml");

    final builder = InflaterBuilder(config);
    final result = await builder.build();
    expect(result.outputs.length, 2);
  });
}