import 'package:flutter_test/flutter_test.dart';

import '../../../lib/xwidget.dart';

main() {
  final parser = ELParserDefinition().build();
  final dependencies = Dependencies({
    "person": Person("Mike", "Jones"),
    "size" : {
      "width": 300.0,
      "height": 200
    },
    "indexes": [1, 0, 2],
    "providers": [
      { "title": "Title #1" },
      { "title": "Title #2" }
    ],
    "functionRefs": {
      "func1param": (a) => a,
      "func2params": (a, b) => [a, b],
    },
    "func1param": (a) => a,
    "func2params": (a, b) => [a, b],
  });

  dependencies.setValue("global.users", [
    { "abc": { "name": "Joe"   } },
    { "xyz": { "name": "Mike"  } },
    { "123": { "name": "Sally" } }
  ]);

  test('Assert global reference parsing', () {
    final result = parser.parse('global.users[indexes[1]].abc.name');
    expect(result.value.evaluate(dependencies), "Joe");
  });

  test('Assert error global reference parsing', () {
    final result = parser.parse('global.users[indexes[2]].123.name');
    expect(result.value.evaluate(dependencies), "Sally");
  });

  test('Assert reference parsing', () {
    final result = parser.parse('providers[indexes[0]].title');
    expect(result.value.evaluate(dependencies), "Title #2");
  });

  test('Assert reference parsing error', () {
    final result = parser.parse('providers[indexes[0]].sku');
    expect(result.value.evaluate(dependencies), null);
  });

  test('Assert String reference concatenation', () {
    final result = parser.parse("providers[indexes[0]].title + ', ' + providers[0].title");
    expect(result.value.evaluate(dependencies), "Title #2, Title #1");
  });

  test('Assert expression in array reference', () {
    final result = parser.parse("providers[4 % length(indexes)].title");
    expect(result.value.evaluate(dependencies), "Title #2");
  });

  test('Assert addition/subtraction precedence', () {
    final result = parser.parse('3 + 5 - 2');
    expect(result.value.evaluate(dependencies), 6);
  });

  test('Assert addition/subtraction/multiplication precedence', () {
    final result = parser.parse('3 + 5 - 2 * 2');
    expect(result.value.evaluate(dependencies), 4);
  });

  test('Assert parentheses precedence', () {
    final result = parser.parse('3 + (5 - 2) * 2');
    expect(result.value.evaluate(dependencies), 9);
  });

  test('Assert num literal less than num literal', () {
    final result = parser.parse('100 < 200');
    expect(result.value.evaluate(dependencies), true);
  });

  test('Assert num literal greater than num literal', () {
    final result = parser.parse('200.0 > 100');
    expect(result.value.evaluate(dependencies), true);
  });

  test('Assert num reference compare to num literal', () {
    final result = parser.parse('size.width > 200');
    expect(result.value.evaluate(dependencies), true);
  });

  test('Assert int division', () {
    final result = parser.parse('6 / 3');
    expect(result.value.evaluate(dependencies), 2);
  });

  test('Assert int division', () {
    final result = parser.parse('0 / 3');
    expect(result.value.evaluate(dependencies), 0);
  });

  test('Assert int division by 0 exception', () {
    expect(
      () => parser.parse('3 / 0').value.evaluate(dependencies),
      throwsException
    );
  });

  test('Assert List item reference throws Exception when index is not an integer', () {
    final deps = Dependencies({
      "items" : [
        { "id": 23 }
      ],
    });
    expect(
      () => parser.parse("items['a'].id").value.evaluate(deps),
      throwsException
    );
  });

  test('Assert List item reference throws Exception when index is null', () {
    final deps = Dependencies({
      "items" : [
        { "id": 23 }
      ],
    });
    expect(
      () => parser.parse("items[a].id").value.evaluate(deps),
      throwsException
    );
  });

  test('Assert reference throws Exception when List item is references like a property', () {
    final deps = Dependencies({
      "items" : [
        { "id": 23 }
      ],
    });
    expect(
      () => parser.parse('items.ll.id').value.evaluate(deps),
      throwsException
    );
  });

  // ==================================
  // precedence tests
  // ==================================

  test('Assert precedence && before ||', () {
    final deps = Dependencies({
      "isTrue" : true,
      "isFalse": false,
    });
    final result = parser.parse('isTrue || isFalse && isFalse');
    expect(result.value.evaluate(deps), true);
  });

  // ==================================
  // if-null tests
  // ==================================

  test('Assert if-null returns 1st value', () {
    final deps = Dependencies({
      "item1": "String1",
      "item2": "String2",
    });
    final result = parser.parse('item1 ?? item2');
    expect(result.value.evaluate(deps), "String1");
  });

  test('Assert if-null return 2nd value', () {
    final deps = Dependencies({
      "item1": null,
      "item2": "String2",
    });
    final result = parser.parse('item1 ?? item2');
    expect(result.value.evaluate(deps), "String2");
  });

  test('Assert if-null return 3rd value', () {
    final deps = Dependencies({
      "item1": null,
      "item2": null,
      "item3": "String3"
    });
    final result = parser.parse('item1 ?? item2 ?? item3');
    expect(result.value.evaluate(deps), "String3");
  });

  test("Assert built-in function 'contains' returns true", () {
    final result = parser.parse("contains('Sand on the beach', 'on')");
    expect(result.value.evaluate(dependencies), true);
  });

  test("Assert built-in function 'isNull' returns true", () {
    final result = parser.parse("isNull(value)");
    expect(result.value.evaluate(dependencies), true);
  });

  test("Assert built-in function 'isNull' returns false", () {
    final result = parser.parse("isNull('value')");
    expect(result.value.evaluate(dependencies), false);
  });

  test("Assert custom function 'addNumbers' returns correct value", () {
    int addNumbers(int n1, [int n2 = 0, int n3 = 0, int n4 = 0, int n5 = 0]) {
      return n1 + n2 + n3 + n4 + n5;
    }
    final deps = Dependencies({
      "addNumbers": addNumbers,
    });
    final result = parser.parse("addNumbers(3,10,4)");
    expect(result.value.evaluate(deps), 17);
  });

  // ==================================
  // function tests
  // ==================================

  test("Assert reference can be used as a function parameter", () {
    final result = parser.parse("func1param(size.height)");
    expect(result.value.evaluate(dependencies), 200);
  });

  test("Assert reference functions work", () {
    final deps = Dependencies({
      "functions": {
        "misc": {
          "test": (a) => {
            "list": [
              Person("John", "Smith"),
              Person("Wendy", "Jones"),
              Person("Sam", "Wilson"),
              Person("April", "Johnson"),
              Person("Mike", "Miller"),
            ]
          }
        }
      }
    });
    final result = parser.parse("functions.misc.test(5).list[4].toString().substring(0,19)");
    expect(result.value.evaluate(deps), "Person{first: Mike,");
  });

  test("Assert function on expression works", () {
    final result = parser.parse("('abc-' + 'xyz').toUpperCase().substring(2,5)");
    expect(result.value.evaluate(dependencies), "C-X");
  });
}

class Person extends Model {
  String get first => getValue("first");
  String get last => getValue("last");

  Person(String first, String last): super({
    "first": first,
    "last": last,
  });

  String fullName() => "$first $last";

  String addSuffix(String suffix) => "${fullName()}, $suffix";

  @override
  String toString() {
    return 'Person{first: $first, last: $last}';
  }
}