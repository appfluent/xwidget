import 'package:flutter_test/flutter_test.dart';

import '../../../lib/xwidget.dart';


main() {

  test('Assert setValue is fast', () {
    final data = <String, dynamic>{};
    final start = DateTime.now().millisecondsSinceEpoch;
    for (var i=0;i<100000;i++) {
      data.setValue("topicsFollowed.top_news", true);
    }
    final millis = DateTime.now().millisecondsSinceEpoch - start;
    expect(millis, {'topicsFollowed': {'top_news': true}});
  });

  test('Assert getValue is fast', () {
    final data = <String, dynamic>{};
    data.setValue("topicsFollowed.top_news.fun.fun", true);
    final start = DateTime.now().millisecondsSinceEpoch;
    for (var i=0;i<1000000;i++) {
      data.getValue("topicsFollowed.top_news.fun.fun");
    }
    final millis = DateTime.now().millisecondsSinceEpoch - start;
    expect(millis, {'topicsFollowed': {'top_news': true}});
  });
}