import '../expression.dart';


class IsEmptyFunctionExpression extends Expression<bool> {
  final dynamic value;

  IsEmptyFunctionExpression(this.value);

  @override
  bool evaluate() {
    final result = Expression.evaluateValue(value);
    if (result == null) return true;
    if (result is String) return result.isEmpty;
    if (result is List) return result.isEmpty;
    if (result is Map) return result.isEmpty;
    if (result is Set) return result.isEmpty;
    return false;
  }
}
