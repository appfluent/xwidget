import 'expression.dart';

class AdditionExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  AdditionExpression(this.left, this.right);

  @override
  dynamic evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null && rightValue == null) return null;
    if (leftValue == null) return rightValue;
    if (rightValue == null) return leftValue;

    if (leftValue is num && rightValue is num) return leftValue + rightValue;
    if (leftValue is Duration && rightValue is Duration) return leftValue + rightValue;
    if (leftValue is DateTime && rightValue is Duration) return leftValue.add(rightValue);
    if (leftValue is Duration && rightValue is DateTime) return rightValue.add(leftValue);

    return leftValue.toString() + rightValue.toString();
  }
}
