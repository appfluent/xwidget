import 'expression.dart';

class ModuloExpression extends Expression<num> {
  final dynamic left;
  final dynamic right;

  ModuloExpression(this.left, this.right);

  @override
  num evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null) throw Exception("Dividend cannot be 'null'");
    if (rightValue == null) throw Exception("Cannot divide by 'null'");

    if (leftValue is num && rightValue is num) return leftValue % rightValue;

    final leftType = leftValue.runtimeType;
    final rightType = rightValue.runtimeType;
    throw Exception("Modulo division not applicable to types '$leftType' and '$rightType'");
  }
}
