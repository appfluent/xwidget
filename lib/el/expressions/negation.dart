import 'expression.dart';


class NegationExpression extends Expression<dynamic> {
  final dynamic value;

  NegationExpression(this.value);

  @override
  dynamic evaluate() {
    final evaluated = Expression.evaluateValue(value);

    // check for null
    if (evaluated == null) return null;

    if (evaluated is num) return -evaluated;
    if (evaluated is bool) return !evaluated;
    if (evaluated is Duration) return -evaluated;

    final evaluatedType = evaluated.runtimeType;
    throw Exception("Negation not applicable to type '$evaluatedType'");
  }
}
