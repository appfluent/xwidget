import 'expression.dart';


class MutableExpression<T> extends Expression<T> {
  T value;

  MutableExpression(this.value);

  @override
  T evaluate() {
    return value;
  }

  Type getType() {
    return value.runtimeType;
  }
}
