import 'package:test/test.dart';

import '../../../bin/src/utils/path_resolver.dart';


void main() {
  test('Test package path resolution', () async {
    PathResolver.packageRoot;
    final path = await PathResolver.relativeToAbsolute("package:flutter/lib/test/image_data.dart");
    expect(path, "");
  });
}