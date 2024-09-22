import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/xwidget.dart' hide startsWith;
import '../testing_utils.dart';

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

  test('Assert invalid reference throws an Exception', () {
    final data = <String, dynamic>{};
    data.setValue("topicsFollowed", []);
    expect(
      () => data.setValue("topicsFollowed.top_news", true),
      exceptionStartsWith("Exception: Unable to read value at index 'top_news' "
          "from Iterable collection of type 'List<dynamic>")
    );
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
    expect(
        () => data.getValue("b!"),
        exceptionStartsWith("Exception: Value at path 'b!' is null.")
    );
  });

  test('Assert null is returned when multi-term path where a non-terminating term is null', () {
    final data = Model({"a": "a"});
    final value = data.getValue("b.a");
    expect(value, null);
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
    final data = Model({"a": "a"}, immutable: true);
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
    final data = Model({});

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
    final data = Model({});

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

  test('Assert hasPath returns TRUE when map path exists', () {
    final model = Model({
      "profile": {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final hasPath = model.hasPath("profile.username");
    expect(hasPath, true);
  });

  test('Assert hasPath returns FALSE when map path does not exist', () {
    final model = Model({
      "profile": {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final hasPath = model.hasPath("profile.dob");
    expect(hasPath, false);
  });

  test('Assert hasPath returns TRUE when list path exists', () {
    final model = Model({
      "profile": {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final hasPath = model.hasPath("profile.emails[0]");
    expect(hasPath, true);
  });

  test('Assert hasPath returns FALSE when list path does not exist', () {
    final model = Model({
      "profile": {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final hasPath = model.hasPath("profile.emails[2]");
    expect(hasPath, false);
  });

  test("Assert map 'key' is returned when referencing map 'key' by index", () {
    final model = Model({
      "profile": {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final key = model.getValue("profile[1]._key");
    expect(key, "emails");
  });

  test("Assert map 'value' is returned when referencing map 'value' by index", () {
    final model = Model({
      "profile": {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final value = model.getValue("profile[1]._value");
    expect(value, [ "1@example.com", "2@example.com" ]);
  });

  test('Assert MapEntry is returned when referencing map entries value by index', () {
    final model = Model({
      "profile": const {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final entry = model.getValue("profile[1]");
    expect(entry.toString(), const MapEntry("emails", [ "1@example.com", "2@example.com" ]).toString());
  });

  test('Assert can access nested values from MapEntry using List index', () {
    final model = Model({
      "profile": const {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final email = model.getValue("profile[1][0]");
    expect(email, "1@example.com");
  });

  test("Assert can access nested values from MapEntry using '_value' and List index", () {
    final model = Model({
      "profile": const {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final email = model.getValue("profile[1]._value[0]");
    expect(email, "1@example.com");
  });

  test("Assert can access MapEntry using List index", () {
    final model = Model({
      "profile": const {
        "username": "user1",
        "emails": [ "1@example.com", "2@example.com" ]
      }
    });

    final entry = model.getValue("profile[1]").toString();
    expect(entry, const MapEntry(
        "emails", [ "1@example.com", "2@example.com" ]
    ).toString());
  });
}