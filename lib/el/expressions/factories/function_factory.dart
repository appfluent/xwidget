import 'package:petitparser/core.dart';

import '../expression.dart';

typedef FunctionBuilder<T> = Expression<T> Function(Parser parser, List<Expression<dynamic>> parameters);

class FunctionFactory<T> {
  final String functionName;
  final int? parameterCount;
  final bool checkParameterCount;
  final FunctionBuilder<T> functionBuilder;

  FunctionFactory({
    required this.functionName,
    required this.functionBuilder,
    this.parameterCount,
    this.checkParameterCount = true,
  }) : assert(parameterCount != null || !checkParameterCount);

  Expression<T> createExpression(Parser parser, List<Expression> parameters) {
    checkParameterLength(parameters, parameterCount);
    return functionBuilder(parser, parameters);
  }

  void checkParameterLength(List<Expression<dynamic>> parameters, int? expectedLength) {
    if (checkParameterCount && parameters.length != expectedLength) {
      throw Exception('Function $functionName expects $expectedLength ${expectedLength == 1 ? 'parameter' : 'parameters'}');
    }
  }
}
