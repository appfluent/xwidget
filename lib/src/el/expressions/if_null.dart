import 'expression.dart';


class IfNullExpression extends Expression {
  final Expression left;
  final Expression right;

  IfNullExpression(this.left, this.right);

  @override
  dynamic evaluate() {
    return left.evaluate() ?? right.evaluate();
  }
}