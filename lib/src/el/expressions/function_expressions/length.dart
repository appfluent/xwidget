import '../expression.dart';


class LengthFunctionExpression extends Expression<int> {
  final dynamic value;

  LengthFunctionExpression(this.value);

  @override
  int evaluate() {
    if (value is String) return value.length;
    if (value is List) return value.length;
    if (value is Map) return value.length;
    if (value is Set) return value.length;
    throw Exception("Function 'length' is invalid for type '${value.runtimeType}'. Valid types are String, List, Map, and Set.");
  }
}
