import '../expression.dart';
import '../function_expressions/contains.dart';
import '../function_expressions/datetime.dart';
import '../function_expressions/duration.dart';
import '../function_expressions/eval.dart';
import '../function_expressions/is_empty.dart';
import '../function_expressions/is_null.dart';
import '../function_expressions/length.dart';
import '../function_expressions/string.dart';
import '../negation.dart';
import 'function_factory.dart';


List<FunctionFactory> getDefaultFunctionFactories() {
  return [
    FunctionFactory(
      functionName: 'contains',
      parameterCount: 2,
      functionBuilder: (parser, params) => ContainsFunction(
        Expression.evaluateValue(params[0]),
        Expression.evaluateValue(params[1]),
      ),
    ),

    FunctionFactory(
      functionName: 'containsKey',
      parameterCount: 2,
      functionBuilder: (parser, params) => ContainsKeyFunction(
        Expression.evaluateValue(params[0]),
        Expression.evaluateValue(params[1]),
      ),
    ),

    FunctionFactory(
      functionName: 'containsValue',
      parameterCount: 2,
      functionBuilder: (parser, params) => ContainsValueFunction(
        Expression.evaluateValue(params[0]),
        Expression.evaluateValue(params[1]),
      ),
    ),

    FunctionFactory(
      functionName: 'diffDateTime',
      parameterCount: 2,
      functionBuilder: (parser, params) => DiffDateTimeFunction(
          Expression.evaluateValue<DateTime>(params[0]),
          Expression.evaluateValue<DateTime>(params[1])
      ),
    ),

    FunctionFactory(
      functionName: 'durationInDays',
      parameterCount: 1,
      functionBuilder: (parser, params) => DurationInDaysFunctionExpression(
          Expression.evaluateValue<Duration>(params[0])
      ),
    ),

    FunctionFactory(
      functionName: 'durationInHours',
      parameterCount: 1,
      functionBuilder: (parser, params) => DurationInHoursFunctionExpression(
          Expression.evaluateValue<Duration>(params[0])
      ),
    ),

    FunctionFactory(
      functionName: 'durationInMinutes',
      parameterCount: 1,
      functionBuilder: (parser, params) => DurationInMinutesFunctionExpression(
          Expression.evaluateValue<Duration>(params[0])
      ),
    ),

    FunctionFactory(
        functionName: 'durationInSeconds',
        parameterCount: 1,
        functionBuilder: (parser, params) => DurationInSecondsFunctionExpression(
            Expression.evaluateValue<Duration>(params[0])
        )
    ),

    FunctionFactory(
      functionName: 'endsWith',
      parameterCount: 2,
      functionBuilder: (parser, params) => EndsWithFunction(
          Expression.evaluateValue<String>(params[0]),
          Expression.evaluateValue<String>(params[1])
      ),
    ),

    FunctionFactory(
      functionName: 'eval',
      parameterCount: 1,
      functionBuilder: (parser, params) => EvalFunction(
        parser,
        Expression.evaluateValue<String>(params[0]),
      ),
    ),

    FunctionFactory(
      functionName: 'formatDateTime',
      parameterCount: 2,
      functionBuilder: (parser, params) => FormatDatetimeFunction(
          Expression.evaluateValue<String>(params[0]),
          Expression.evaluateValue<DateTime>(params[1])
      ),
    ),

    FunctionFactory(
      functionName: 'isEmpty',
      parameterCount: 1,
      functionBuilder: (parser, params) => IsEmptyFunctionExpression(params[0]),
    ),

    FunctionFactory(
      functionName: 'isNotEmpty',
      parameterCount: 1,
      functionBuilder: (parser, params) => NegationExpression(IsEmptyFunctionExpression(params[0])),
    ),

    FunctionFactory(
      functionName: 'isNull',
      parameterCount: 1,
      functionBuilder: (parser, params) => IsNullFunctionExpression(params[0]),
    ),

    FunctionFactory(
      functionName: 'length',
      parameterCount: 1,
      functionBuilder: (parser, params) => LengthFunctionExpression(Expression.evaluateValue(params[0])),
    ),

    FunctionFactory(
      functionName: 'matches',
      parameterCount: 2,
      functionBuilder: (parser, params) => MatchesFunction(
        Expression.evaluateValue<String>(params[0]),
        Expression.evaluateValue<String>(params[1])
      ),
    ),

    FunctionFactory(
      functionName: 'now',
      parameterCount: 0,
      functionBuilder: (parser, params) => NowFunction(),
    ),

    FunctionFactory(
      functionName: 'nowInUtc',
      parameterCount: 0,
      functionBuilder: (parser, params) => NowInUtcFunction(),
    ),

    FunctionFactory(
      functionName: 'startsWith',
      parameterCount: 2,
      functionBuilder: (parser, params) => StartsWithFunction(
        Expression.evaluateValue<String>(params[0]),
        Expression.evaluateValue<String>(params[1])
      ),
    ),

    FunctionFactory(
      functionName: 'substring',
      checkParameterCount: false,
      functionBuilder: (parser, params) => SubstringFunction(
          Expression.evaluateValue<String>(params[0]),
          Expression.evaluateValue<int>(params.length > 1 ? params[1] : 0),
          Expression.evaluateValue<int>(params.length > 2 ? params[2] : -1)
      ),
    ),

    FunctionFactory(
      functionName: 'toDateTime',
      parameterCount: 1,
      functionBuilder: (parser, params) => ToDateTimeFunction(
          Expression.evaluateValue(params[0])
      ),
    ),

    FunctionFactory(
      functionName: 'toDuration',
      parameterCount: 1,
      functionBuilder: (parser, params) => ToDurationFunction(
          Expression.evaluateValue<String>(params[0])
      ),
    ),

    FunctionFactory(
      functionName: 'toString',
      parameterCount: 1,
      functionBuilder: (parser, params) => ToStringFunction(Expression.evaluateValue(params[0])),
    ),
  ];
}
