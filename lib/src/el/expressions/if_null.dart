import '../../xwidget.dart';
import 'expression.dart';

class IfNullExpression extends Expression {
  final Expression left;
  final Expression right;

  IfNullExpression(this.left, this.right);

  @override
  dynamic evaluate(Dependencies dependencies) {
    return left.evaluate(dependencies) ?? right.evaluate(dependencies);
  }
}
