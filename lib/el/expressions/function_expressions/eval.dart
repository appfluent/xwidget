import 'package:petitparser/core.dart';

import '../expression.dart';


class EvalFunction extends Expression<dynamic> {
  final Parser parser;
  final String? value;

  EvalFunction(this.parser, this.value);

  @override
  dynamic evaluate() {
    final expression = value;
    if (expression != null && expression.isNotEmpty) {
      final result = parser.parse(expression);
      if (result.isSuccess) {
        return result.value.evaluate();
      } else {
        throw Exception("Failed to evaluate '$expression'. ${result.message}");
      }
    }
  }
}