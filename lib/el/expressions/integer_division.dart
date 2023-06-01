import 'expression.dart';


class IntegerDivisionExpression extends Expression<int> {
  final dynamic left;
  final dynamic right;

  IntegerDivisionExpression(this.left, this.right);

  @override
  int evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null) throw Exception("Dividend cannot be 'null'");
    if (rightValue == null) throw Exception("Divisor cannot be 'null'");

    if (leftValue is num && rightValue is num) return leftValue ~/ rightValue;

    final leftType = leftValue.runtimeType;
    final rightType = rightValue.runtimeType;
    throw Exception("Integer division not applicable to types '$leftType' and '$rightType'");
  }
}
