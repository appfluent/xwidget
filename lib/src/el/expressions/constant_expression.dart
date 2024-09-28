import '../../xwidget.dart';
import 'expression.dart';

class ConstantExpression<T> extends Expression<T> {
  final T value;

  ConstantExpression(this.value);

  @override
  T evaluate(Dependencies dependencies) {
    return value;
  }
}
