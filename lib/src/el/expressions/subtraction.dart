import '../../xwidget.dart';
import 'expression.dart';

class SubtractionExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  SubtractionExpression(this.left, this.right);

  @override
  dynamic evaluate(Dependencies dependencies) {
    final leftValue = evaluateValue(left, dependencies);
    final rightValue = evaluateValue(right, dependencies);

    if (leftValue == null && rightValue == null) return null;
    if (leftValue == null) return rightValue; // TODO: throw exception ?
    if (rightValue == null) return leftValue;
    if (leftValue is DateTime && rightValue is Duration) {
      return leftValue.subtract(rightValue);
    }

    try {
      return leftValue - rightValue;
    } catch(e) {
      throw Exception("Subtraction is not applicable to types "
          "'${leftValue.runtimeType}' and '${rightValue.runtimeType}'");
    }
  }
}
