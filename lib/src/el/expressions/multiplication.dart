import '../../xwidget.dart';
import 'expression.dart';

class MultiplicationExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  MultiplicationExpression(this.left, this.right);

  @override
  dynamic evaluate(Dependencies dependencies) {
    final leftValue = evaluateValue(left, dependencies);
    final rightValue = evaluateValue(right, dependencies);

    if (leftValue == null && rightValue == null) return null;
    if (leftValue == null || rightValue == null) throw Exception("Cannot multiply by 'null'");
    if (leftValue is num && rightValue is Duration) return rightValue * leftValue;

    try {
      return leftValue * rightValue;
    } catch(e) {
      throw Exception("Multiplication is not applicable to types "
          "'${leftValue.runtimeType}' and '${rightValue.runtimeType}'");
    }
  }
}
