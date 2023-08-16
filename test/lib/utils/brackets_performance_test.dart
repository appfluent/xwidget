import 'package:flutter_test/flutter_test.dart';

import 'package:xwidget/xwidget.dart';


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


class User extends Data {
  String get name => this["name"];
  String get account => this["account"];
  User(Map<String, dynamic> params, [bool immutable = true]): super(params, immutable);
}

class Account extends Data {
  String get number => this["number"];
  int get amount => this["amount"];
  Account(Map<String, dynamic> params, [bool immutable = true]): super(params, immutable);
}