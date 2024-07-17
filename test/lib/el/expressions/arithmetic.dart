import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/src/el/expressions/addition.dart';
import '../../../../lib/src/el/expressions/subtraction.dart';
import '../../../../lib/src/el/expressions/multiplication.dart';
import '../../../../lib/src/el/expressions/division.dart';
import '../../../../lib/src/el/expressions/modulo.dart';
import '../../../../lib/src/el/expressions/integer_division.dart';

main() {

  // addition

  test('Assert + implementation', () {
    final left = Arithmetic("left");
    final right = Arithmetic("right");
    final exp = AdditionExpression(left, right);
    expect(exp.evaluate(), Arithmetic("left + right"));
  });

  test('Assert string concatenation', () {
    final exp = AdditionExpression("left", "right");
    expect(exp.evaluate(), "leftright");
  });

  test('Assert Duration + DateTime addition', () {
    final left = Duration(seconds: 10);
    final right = DateTime.parse("2000-01-01 00:00:00");
    final exp = AdditionExpression(left, right);
    expect(exp.evaluate(), DateTime.parse("2000-01-01 00:00:10"));
  });

  test('Assert DateTime + Duration addition', () {
    final left = DateTime.parse("2000-01-01 00:00:00");
    final right = Duration(seconds: 10);
    final exp = AdditionExpression(left, right);
    expect(exp.evaluate(), DateTime.parse("2000-01-01 00:00:10"));
  });

  // subtraction

  test('Assert - implementation', () {
    final left = Arithmetic("left");
    final right = Arithmetic("right");
    final exp = SubtractionExpression(left, right);
    expect(exp.evaluate(), Arithmetic("left - right"));
  });

  test('Assert DateTime - Duration subtraction', () {
    final left = DateTime.parse("2000-01-01 00:00:00");
    final right = Duration(seconds: 10);
    final exp = SubtractionExpression(left, right);
    expect(exp.evaluate(), DateTime.parse("1999-12-31 23:59:50"));
  });

  // multiplication

  test('Assert * implementation', () {
    final left = Arithmetic("left");
    final right = Arithmetic("right");
    final exp = MultiplicationExpression(left, right);
    expect(exp.evaluate(), Arithmetic("left * right"));
  });

  test('Assert int * Duration multiplication', () {
    final left = 2;
    final right = Duration(seconds: 10);
    final exp = MultiplicationExpression(left, right);
    expect(exp.evaluate(), Duration(seconds: 20));
  });

  test('Assert Duration * int multiplication', () {
    final left = Duration(seconds: 10);
    final right = 3;
    final exp = MultiplicationExpression(left, right);
    expect(exp.evaluate(), Duration(seconds: 30));
  });

  test('Assert double * Duration multiplication', () {
    final left = 2.5;
    final right = Duration(seconds: 10);
    final exp = MultiplicationExpression(left, right);
    expect(exp.evaluate(), Duration(seconds: 25));
  });

  test('Assert Duration * double multiplication', () {
    final left = Duration(seconds: 10);
    final right = 3.5;
    final exp = MultiplicationExpression(left, right);
    expect(exp.evaluate(), Duration(seconds: 35));
  });

  // division

  test('Assert / implementation', () {
    final left = Arithmetic("left");
    final right = Arithmetic("right");
    final exp = DivisionExpression(left, right);
    expect(exp.evaluate(), Arithmetic("left / right"));
  });

  test('Assert Duration / int division', () {
    final left = Duration(seconds: 10);
    final right = 3;
    final exp = DivisionExpression(left, right);
    expect(exp.evaluate(), Duration(microseconds: 3333333));
  });

  // modulo

  test('Assert % implementation', () {
    final left = Arithmetic("left");
    final right = Arithmetic("right");
    final exp = ModuloExpression(left, right);
    expect(exp.evaluate(), Arithmetic("left % right"));
  });

  // integer division

  test('Assert ~/ implementation', () {
    final left = Arithmetic("left");
    final right = Arithmetic("right");
    final exp = IntegerDivisionExpression(left, right);
    expect(exp.evaluate(), Arithmetic("left ~/ right"));
  });
}

class Arithmetic {
  final String value;

  Arithmetic(this.value);

  @override
  Arithmetic operator +(Arithmetic right) {
    return Arithmetic("$value + ${right.value}");
  }

  @override
  Arithmetic operator -(Arithmetic right) {
    return Arithmetic("$value - ${right.value}");
  }

  @override
  Arithmetic operator *(Arithmetic right) {
    return Arithmetic("$value * ${right.value}");
  }

  @override
  Arithmetic operator /(Arithmetic right) {
    return Arithmetic("$value / ${right.value}");
  }

  @override
  Arithmetic operator %(Arithmetic right) {
    return Arithmetic("$value % ${right.value}");
  }

  @override
  Arithmetic operator ~/(Arithmetic right) {
    return Arithmetic("$value ~/ ${right.value}");
  }

  @override
  String toString() {
    return 'Arithmetic{value: $value}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Arithmetic &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}