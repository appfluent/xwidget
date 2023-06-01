import 'expression.dart';


class MultiplicationExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  MultiplicationExpression(this.left, this.right);

  @override
  dynamic evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null && rightValue == null) return null;
    if (leftValue == null || rightValue == null) throw Exception("Cannot multiply by 'null'");

    if (leftValue is num && rightValue is num) return leftValue * rightValue;
    if (leftValue is Duration && rightValue is num) return leftValue * rightValue;
    if (leftValue is num && rightValue is Duration) return rightValue * leftValue;

    final leftType = leftValue.runtimeType;
    final rightType = rightValue.runtimeType;
    throw Exception("Multiplication not applicable to types '$leftType' and '$rightType'");
  }
}