import 'expression.dart';


class NullableToNonNullableExpression<T> extends Expression<T> {
  final Expression<T?> value;

  NullableToNonNullableExpression(this.value);

  @override
  T evaluate() {
    var result = value.evaluate();
    if (result == null) {
      throw Exception('Instance of type $T is null and can\'t be converted to non-nullable');
    }
    return result;
  }
}
