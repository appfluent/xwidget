import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/xwidget.dart';

main() {

  test('Assert setValue', () {
    final data = <String, dynamic>{};
    data.setValue("topicsFollowed.top_news", true);
    expect(data, {'topicsFollowed': {'top_news': true}});
  });

  test('Assert ValueNotifier', () {
    final notifier = ValueNotifier<dynamic>("5");
    final data = <String, dynamic>{};
    data.setValue("topicsFollowed.top_news", notifier);
    data.setValue("topicsFollowed.top_news", true);
    expect(data.getValue("topicsFollowed.top_news"), true);
  });

  test('Assert ValueNotifier again', () {
    final notifier = ValueNotifier<dynamic>("5");
    final data = <String, dynamic>{};
    data.setValue("topicsFollowed.top_news.test", notifier);
    data.setValue("topicsFollowed.top_news.test", true);
    expect(data.getValue("topicsFollowed.top_news.test"), true);
  });

  test('Assert replace', () {
    final data = <String, dynamic>{};
    data.setValue("topicsFollowed", []);
    expect(() => data.setValue("topicsFollowed.top_news", true), throwsException);
  });

  test('Assert ImmutableData single-term path returns a null and not an exception', () {
    final data = Data({"a": "a"});
    expect(data["b"], null);
  });

  test('Assert ImmutableData single-path null-safety test', () {
    final data = Data({"a": "a"});
    expect(data["b?"], null);
  });

  test('Assert ImmutableData single-term non-nullable path throws an exception', () {
    final data = Data({"a": "a"});
    expect(() => data["b!"], throwsException);
  });

  test('Assert ImmutableData multi-term path where a non-terminating term is null throws an exception', () {
    final data = Data({"a": "a"});
    expect(() => data["b.a"], throwsException);
  });

  test('Assert ImmutableData multi-path null-safety test', () {
    final data = Data({"a": "a"});
    expect(data["b?.a"], null);
  });

  test('Assert ImmutableData is mutable', () {
    final data = Data({"a": "a"}, false);
    data["b.c"] = "c";
    expect(data, {"a": "a", "b": {"c": "c"}});
  });

  test('Assert get list value', () {
    final data = Data({"list": ["A", "B", "C"]}, true);
    expect(data["list[1]"], "B");
  });

  test('Assert update data in list', () {
    final data = Data({"list": ["A", "B", "C"]}, false);
    data["list[1]"] = "D";
    expect(data["list"], ["A", "D", "C"]);
  });

  test('Assert data removed from list', () {
    final data = Data({"lists": {"a":["A", "B", "C"]}, "b":["X", "Y", "Z"]}, false);
    data.removeValue("lists.a[1]");
    expect(data["lists.a"], ["A", "C"]);
  });

  test('Assert item from multi-dimensional list', () {
    final data = Data({"list": [["A", "B", "C"]]}, false);
    expect(data["list[0][1]"], "B");
  });

  test('Assert append data to end of list', () {
    final data = Data({"list": ["A", "B", "C"]}, false);
    data.setValue("list[3]", "D");
    expect(data["list"], ["A", "B", "C", "D"]);
  });

  test('Assert insert data past range in nullable list', () {
    final data = Data({"list": <dynamic>["A", "B", "C"]}, false);
    data.setValue("list[4]", "D");
    expect(data["list"], ["A", "B", "C", null, "D"]);
  });

  test('Assert insert data past range in non-nullable list', () {
    final data = Data({"list": ["A", "B", "C"]}, false);
    expect(() => data["list[4]"] = "D", throwsException);
  });
}