import 'expression.dart';

class LessThanExpression extends Expression<bool> {
  final dynamic left;
  final dynamic right;

  LessThanExpression(this.left, this.right);

  @override
  bool evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null && rightValue == null) return false;
    if (leftValue == null) return true;
    if (rightValue == null) return false;

    if (leftValue is num && rightValue is num) return leftValue < rightValue;
    if (leftValue is Duration && rightValue is Duration) return leftValue < rightValue;
    if (leftValue is DateTime && rightValue is DateTime) return leftValue.isBefore(rightValue);
    if (leftValue is String && rightValue is String) return leftValue.compareTo(rightValue) < 0;

    final leftType = leftValue.runtimeType;
    final rightType = rightValue.runtimeType;
    throw Exception("Less-Than comparison not applicable to types '$leftType' and '$rightType'");
  }
}
