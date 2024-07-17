import 'expression.dart';

class MultiplicationExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  MultiplicationExpression(this.left, this.right);

  @override
  dynamic evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

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
