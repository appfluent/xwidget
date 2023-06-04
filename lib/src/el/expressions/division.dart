import 'expression.dart';


class DivisionExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  DivisionExpression(this.left, this.right);

  @override
  dynamic evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null) throw Exception("Dividend cannot be 'null'");
    if (rightValue == null) throw Exception("Divisor cannot be 'null'");

    if (rightValue is num) {
      if (rightValue == 0) throw Exception("Cannot divide by '0'");
      if (leftValue is num) return leftValue / rightValue;
      if (leftValue is Duration && rightValue is int) return leftValue ~/ rightValue;
    }

    final leftType = leftValue.runtimeType;
    final rightType = rightValue.runtimeType;
    throw Exception("Division not applicable to types '$leftType' and '$rightType'");
  }
}