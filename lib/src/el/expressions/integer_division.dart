import 'expression.dart';

class IntegerDivisionExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  IntegerDivisionExpression(this.left, this.right);

  @override
  dynamic evaluate() {
    final leftValue = Expression.evaluateValue(left);
    final rightValue = Expression.evaluateValue(right);

    // check null conditions
    if (leftValue == null) throw Exception("Dividend cannot be 'null'");
    if (rightValue == null) throw Exception("Divisor cannot be 'null'");

    try {
      return leftValue ~/ rightValue;
    } catch(e) {
      throw Exception("Integer division is not applicable to types "
          "'${leftValue.runtimeType}' and '${rightValue.runtimeType}'");
    }
  }
}
