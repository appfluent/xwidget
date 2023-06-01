import 'expression.dart';


class LessThanOrEqualToExpression extends Expression<bool> {
  final dynamic left;
  final dynamic right;

  LessThanOrEqualToExpression(this.left, this.right);

  @override
  bool evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null && rightValue == null) return true;
    if (leftValue == null) return true;
    if (rightValue == null) return false;

    if (leftValue is num && rightValue is num) return leftValue <= rightValue;
    if (leftValue is Duration && rightValue is Duration) return leftValue <= rightValue;
    if (leftValue is DateTime && rightValue is DateTime) return leftValue.isBefore(rightValue) || leftValue.isAtSameMomentAs(rightValue);
    if (leftValue is String && rightValue is String) return leftValue.compareTo(rightValue) <= 0;

    final leftType = leftValue.runtimeType;
    final rightType = rightValue.runtimeType;
    throw Exception("Less-Than-Or-Equal-To comparison not applicable to types '$leftType' and '$rightType'");
  }
}