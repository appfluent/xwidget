import '../expression.dart';


class IsNullFunctionExpression extends Expression<bool> {
  final dynamic value;

  IsNullFunctionExpression(this.value);

  @override
  bool evaluate() {
    final result = Expression.evaluateValue(value);
    return result == null;
  }
}
