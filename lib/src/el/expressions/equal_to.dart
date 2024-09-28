import '../../xwidget.dart';
import 'expression.dart';

class EqualToExpression extends Expression<bool> {
  final dynamic left;
  final dynamic right;

  EqualToExpression(this.left, this.right);

  @override
  bool evaluate(Dependencies dependencies) {
    final leftValue = evaluateValue(left, dependencies);
    final rightValue = evaluateValue(right, dependencies);

    // check null conditions
    if (leftValue == null && rightValue == null) return true;
    if (leftValue == null) return false;
    if (rightValue == null) return false;

    if (leftValue is DateTime && rightValue is DateTime) {
      return leftValue.isAtSameMomentAs(rightValue);
    }
    if (leftValue is String && rightValue is String) {
      return leftValue.compareTo(rightValue) == 0;
    }
    if (leftValue is Enum && rightValue is String) {
      return leftValue.name == rightValue;
    }
    if (leftValue is String && rightValue is Enum) {
      return leftValue == rightValue.name;
    }
    return leftValue == rightValue;
  }
}
