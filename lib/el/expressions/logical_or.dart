import 'expression.dart';


class LogicalOrExpression extends Expression<bool> {
  final Expression left;
  final Expression right;

  LogicalOrExpression(this.left, this.right);

  @override
  bool evaluate() {
    return left.evaluate() || right.evaluate();
  }
}
