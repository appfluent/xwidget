import 'expression.dart';


class SubtractionExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  SubtractionExpression(this.left, this.right);

  @override
  dynamic evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null && rightValue == null) return null;
    if (leftValue == null) return rightValue; // TODO: throw exception ?
    if (rightValue == null) return leftValue;

    if (leftValue is num && rightValue is num) return leftValue - rightValue;
    if (leftValue is Duration && rightValue is Duration) return leftValue - rightValue;
    if (leftValue is DateTime && rightValue is Duration) return leftValue.subtract(rightValue);

    final leftType = leftValue.runtimeType;
    final rightType = rightValue.runtimeType;
    throw Exception("Subtraction not applicable to types '$leftType' and '$rightType'");
  }
}