import '../../xwidget.dart';
import 'expression.dart';

class AdditionExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  AdditionExpression(this.left, this.right);

  @override
  dynamic evaluate(Dependencies dependencies) {
    final leftValue = evaluateValue(left, dependencies);
    final rightValue = evaluateValue(right, dependencies);

    if (leftValue == null && rightValue == null) return null;
    if (leftValue == null) return rightValue;
    if (rightValue == null) return leftValue;
    if (leftValue is DateTime && rightValue is Duration) {
      return leftValue.add(rightValue);
    }
    if (leftValue is Duration && rightValue is DateTime) {
      return rightValue.add(leftValue);
    }

    try {
      return leftValue + rightValue;
    } catch(e) {
      throw Exception("Addition is not applicable to types "
          "'${leftValue.runtimeType}' and '${rightValue.runtimeType}'");
    }
  }
}
