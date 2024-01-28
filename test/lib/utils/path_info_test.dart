import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/xwidget.dart';


main() {

  test('Assert setValue', () {
    final path = PathInfo.parsePath("list[3]");
    print(path);
    // expect(data, {'topicsFollowed': {'top_news': true}});
  });


}