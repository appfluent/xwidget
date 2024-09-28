import '../../xwidget.dart';
import 'expression.dart';

class ConditionalExpression<T> extends Expression<T> {
  Expression<bool> condition;
  Expression<T> trueValue;
  Expression<T> falseValue;

  ConditionalExpression(this.condition, this.trueValue, this.falseValue);

  @override
  T evaluate(Dependencies dependencies) {
    return condition.evaluate(dependencies)
        ? trueValue.evaluate(dependencies)
        : falseValue.evaluate(dependencies);
  }
}
