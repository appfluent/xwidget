import 'expression.dart';


class LogicalAndExpression extends Expression<bool> {
  final Expression left;
  final Expression right;

  LogicalAndExpression(this.left, this.right);

  @override
  bool evaluate() {
    return left.evaluate() && right.evaluate();
  }
}
