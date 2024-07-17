import 'expression.dart';

class DivisionExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  DivisionExpression(this.left, this.right);

  @override
  dynamic evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    if (leftValue == null) throw Exception("Dividend cannot be 'null'");
    if (rightValue == null) throw Exception("Divisor cannot be 'null'");
    if (rightValue is num) {
      if (rightValue == 0) throw Exception("Cannot divide by '0'");
      if (leftValue is Duration && rightValue is int) {
        return leftValue ~/ rightValue;
      }
    }

    try {
      return leftValue / rightValue;
    } catch(e) {
      throw Exception("Division is not applicable to types "
          "'${leftValue.runtimeType}' and '${rightValue.runtimeType}'");
    }
  }
}
