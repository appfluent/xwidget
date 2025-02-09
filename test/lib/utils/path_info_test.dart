import 'package:flutter_test/flutter_test.dart';
import 'package:xwidget/xwidget.dart';


main() {

  test('Assert setValue', () {
    final path = PathInfo.parsePath("list[3]");
    print(path);
    // expect(data, {'topicsFollowed': {'top_news': true}});
  });
}