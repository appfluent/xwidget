import 'expression.dart';


class DynamicFunction extends Expression<dynamic> {
  final Function function;
  final List<dynamic> params;

  DynamicFunction(this.function, this.params);

  @override
  dynamic evaluate() {
    final p = _ParamEvaluator(params);
    switch (params.length) {
      case 0: return function();
      case 1: return function(p[0]);
      case 2: return function(p[0], p[1]);
      case 3: return function(p[0], p[1], p[2]);
      case 4: return function(p[0], p[1], p[2], p[3]);
      case 5: return function(p[0], p[1], p[2], p[3], p[4]);
      case 6: return function(p[0], p[1], p[2], p[3], p[4], p[5]);
      case 7: return function(p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
      case 8: return function(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7]);
      case 9: return function(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]);
      case 10: return function(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9]);
      default: throw Exception("DynamicFunction can have up to 10 params. Received ${params.length}");
    }
  }
}

class _ParamEvaluator {
  final List<dynamic> params;

  _ParamEvaluator(this.params);

  dynamic operator [](int index) {
    return Expression.evaluateValue(params[index]);
  }
}
