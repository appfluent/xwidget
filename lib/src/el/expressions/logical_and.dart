import 'expression.dart';

import '../../xwidget.dart';

class LogicalAndExpression extends Expression<bool> {
  final Expression left;
  final Expression right;

  LogicalAndExpression(this.left, this.right);

  @override
  bool evaluate(Dependencies dependencies) {
    return left.evaluate(dependencies) && right.evaluate(dependencies);
  }
}
