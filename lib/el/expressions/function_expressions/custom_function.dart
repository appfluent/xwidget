import '../expression.dart';


typedef CustomFunction<T> = T Function(List parameters);

class CustomFunctionExpression<T> extends Expression<T> {
  final List<Expression> parameters;
  final CustomFunction function;

  CustomFunctionExpression(this.parameters, this.function);

  @override
  T evaluate() {
    return function(parameters.map((e) => e.evaluate()).toList());
  }
}
