import 'package:flutter_test/flutter_test.dart';

import 'package:xwidget/src/el/parser.dart';


main() {

  final data = <String, dynamic>{
    "size" : {
      "width": 300.0,
      "height": 200
    },
    "indexes": [1, 0],
    "providers": [
      { "title": "Title #1" },
      { "title": "Title #2" }
    ]
  };

  test('Assert reference parsing', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('providers[indexes[0]].title').value.evaluate(), "Title #2");
  });

  test('Assert String reference concatenation', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse("providers[indexes[0]].title + ', ' + providers[0].title").value.evaluate(), "Title #2, Title #1");
  });

  test('Assert expression in array reference', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse("providers[3 % length(indexes)].title").value.evaluate(), "Title #2");
  });

  test('Assert addition/subtraction precedence', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('3 + 5 - 2').value.evaluate(), 6);
  });

  test('Assert addition/subtraction/multiplication precedence', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('3 + 5 - 2 * 2').value.evaluate(), 4);
  });

  test('Assert parentheses precedence', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('3 + (5 - 2) * 2').value.evaluate(), 9);
  });

  test('Assert num literal less than num literal', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('100 < 200').value.evaluate(), true);
  });

  test('Assert num literal greater than num literal', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('200.0 > 100').value.evaluate(), true);
  });

  test('Assert num reference compare to num literal', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('size.width > 200').value.evaluate(), true);
  });

  test('Assert int division', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('6 / 3').value.evaluate(), 2);
  });

  test('Assert int division', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('0 / 3').value.evaluate(), 0);
  });

  test('Assert int division by 0 exception', () {
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(() => parser.parse('3 / 0').value.evaluate(), throwsException);
  });

  // ==================================
  // precedence tests
  // ==================================

  test('Assert precedence && before ||', () {
    final data = <String, dynamic>{
      "isTrue" : true,
      "isFalse": false,
    };
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('isTrue || isFalse && isFalse').value.evaluate(), true);
  });

  // ==================================
  // if-null tests
  // ==================================

  test('Assert if-null returns 1st value', () {
    final data = <String, dynamic>{
      "item1": "String1",
      "item2": "String2",
    };
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('item1 ?? item2').value.evaluate(), "String1");
  });

  test('Assert if-null return 2nd value', () {
    final data = <String, dynamic>{
      "item1": null,
      "item2": "String2",
    };
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('item1 ?? item2').value.evaluate(), "String2");
  });

  test('Assert if-null return 3rd value', () {
    final data = <String, dynamic>{
      "item1": null,
      "item2": null,
      "item3": "String3"
    };
    final definition = ELParserDefinition(data: data);
    final parser = definition.build(start: definition.expression);
    expect(parser.parse('item1 ?? item2 ?? item3').value.evaluate(), "String3");
  });
}
