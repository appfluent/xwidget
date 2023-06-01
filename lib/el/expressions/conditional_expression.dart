import 'expression.dart';


class ConditionalExpression<T> extends Expression<T> {
  Expression<bool> condition;
  Expression<T> trueValue;
  Expression<T> falseValue;

  ConditionalExpression(this.condition, this.trueValue, this.falseValue);

  @override
  T evaluate() {
    return condition.evaluate() ? trueValue.evaluate() : falseValue.evaluate();
  }
}
