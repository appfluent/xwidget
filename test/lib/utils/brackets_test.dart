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

  test('Assert single-term path returns a null and not an exception', () {
    final data = Model({"a": "a"});
    expect(data.getValue("b"), null);
  });

  test('Assert single-path null-safety test', () {
    final data = Model({"a": "a"});
    expect(data.getValue("b?"), null);
  });

  test('Assert single-term non-nullable path throws an exception', () {
    final data = Model({"a": "a"});
    expect(() => data.getValue("b!"), throwsException);
  });

  test('Assert multi-term path where a non-terminating term is null throws an exception', () {
    final data = Model({"a": "a"});
    expect(() => data.getValue("b.a"), throwsException);
  });

  test('Assert multi-path null-safety test', () {
    final data = Model({"a": "a"});
    expect(data.getValue("b?.a"), null);
  });

  test('Assert is mutable', () {
    final data = Model({"a": "a"});
    data.setValue("b.c", "c");
    expect(data, {"a": "a", "b": {"c": "c"}});
  });

  test('Assert is immutable', () {
    final data = Model.immutable({"a": "a"});
    expect(() => data.setValue("b.c", "c"), throwsUnimplementedError);
  });

  test('Assert get list value', () {
    final data = Model({"list": ["A", "B", "C"]});
    expect(data.getValue("list[1]"), "B");
  });

  test('Assert update data in list', () {
    final data = Model({"list": ["A", "B", "C"]});
    data.setValue("list[1]", "D");
    expect(data["list"], ["A", "D", "C"]);
  });

  test('Assert data removed from list', () {
    final data = Model({"lists": {"a":["A", "B", "C"]}, "b":["X", "Y", "Z"]});
    data.removeValue("lists.a[1]");
    expect(data.getValue("lists.a"), ["A", "C"]);
  });

  test('Assert item from multi-dimensional list', () {
    final data = Model({"list": [["A", "B", "C"]]});
    expect(data.getValue("list[0][1]"), "B");
  });

  test('Assert append data to end of list', () {
    final data = Model({"list": ["A", "B", "C"]});
    data.setValue("list[3]", "D");
    expect(data.getValue("list"), ["A", "B", "C", "D"]);
  });

  test('Assert insert data past range in nullable list', () {
    final data = Model({"list": <dynamic>["A", "B", "C"]});
    data.setValue("list[4]", "D");
    expect(data["list"], ["A", "B", "C", null, "D"]);
  });

  test('Assert insert data past range in non-nullable list', () {
    final data = Model({"list": ["A", "B", "C"]});
    expect(() => data.setValue("list[4]", "D"), throwsException);
  });

  test('Assert can add listeners to empty Model', () {
    final data = Model();

    int usersChanged = 0;
    final usersNotifier = data.listenForChanges("users", null, null);
    usersNotifier.addListener(() => usersChanged++);

    int user1Changed = 0;
    final user1Notifier = data.listenForChanges("users.user1", null, null);
    user1Notifier.addListener(() => user1Changed++);

    int user2Changed = 0;
    final user2Notifier = data.listenForChanges("users.user2", null, null);
    user2Notifier.addListener(() => user2Changed++);

    data.setValue("users.user1.email", "user2@gexample.com");
    expect([usersChanged, user1Changed, user2Changed], [1,1,0]);
  });

  test('Assert parent listen not called when adding child listeners', () {
    final data = Model();

    int usersChanged = 0;
    final usersNotifier = data.listenForChanges("users", null, null);
    usersNotifier.addListener(() => usersChanged++);

    int user1Changed = 0;
    final user1Notifier = data.listenForChanges("users.user1", null, null);
    user1Notifier.addListener(() => user1Changed++);

    int user2Changed = 0;
    final user2Notifier = data.listenForChanges("users.user2", null, null);
    user2Notifier.addListener(() => user2Changed++);

    expect([usersChanged, user1Changed, user2Changed], [0,0,0]);
  });

  test('Assert parent and child listeners called when child data changed', () {
    final data = <String, dynamic>{
      "users": <String, dynamic>{
        "user1": <String, dynamic>{ "email": "@", "phone": "0" },
        "user2": <String, dynamic>{ "email": "@", "phone": "0" }
      }
    };

    int usersChanged = 0;
    final usersNotifier = data.listenForChanges("users", null, null);
    usersNotifier.addListener(() => usersChanged++);

    int user1Changed = 0;
    final user1Notifier = data.listenForChanges("users.user1", null, null);
    user1Notifier.addListener(() => user1Changed++);

    int user2Changed = 0;
    final user2Notifier = data.listenForChanges("users.user2", null, null);
    user2Notifier.addListener(() => user2Changed++);

    data.setValue("users.user2.email", "user2@gexample.com");
    expect([usersChanged, user1Changed, user2Changed], [1,0,1]);
  });


  test('Assert nothing', () {
    // don't do this - no types
    final model = Model({
      "profile": {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    int profileChanged = 0;
    final profileNotifier = model.listenForChanges("profile", null, null);
    profileNotifier.addListener(() => profileChanged++);
    model.setValue("profile.emails[2]", "3@example.com");

    print(profileChanged);
  });

}