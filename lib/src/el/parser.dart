import 'package:petitparser/petitparser.dart';

import '../utils/brackets.dart';
import 'expressions/conditional_expression.dart';
import 'expressions/equal_to.dart';
import 'expressions/function_expressions/dynamic.dart';
import 'expressions/if_null.dart';
import 'expressions/less_than.dart';

import 'expressions/factories/default_functions.dart';
import 'expressions/factories/function_factory.dart';
import 'expressions/nullable_to_non_nullable.dart';
import 'expressions/addition.dart';
import 'expressions/constant_expression.dart';
import 'expressions/division.dart';
import 'expressions/expression.dart';

import 'expressions/integer_division.dart';
import 'expressions/less_than_or_equal_to.dart';
import 'expressions/logical_and.dart';
import 'expressions/logical_or.dart';
import 'expressions/modulo.dart';
import 'expressions/multiplication.dart';
import 'expressions/negation.dart';
import 'expressions/subtraction.dart';
import 'grammar.dart';


class ELParserDefinition extends ELGrammarDefinition {
  final Map<String, dynamic> data;
  final Map<String, dynamic> globalData;
  final Map<String, FunctionFactory> _functionFactories;
  late Parser _parser;

  ELParserDefinition({
    required this.data,
    required this.globalData,
    List<FunctionFactory> customFunctionFactories = const [],
  }) : _functionFactories = {
    for (final factory in customFunctionFactories) factory.functionName: factory,
    for (final factory in getDefaultFunctionFactories()) factory.functionName: factory
  };

  @override
  Parser<T> build<T>({Function? start, List<Object> arguments = const []}) {
    final parser = super.build<T>(start: start, arguments: arguments);
    _parser = parser;
    return parser;
  }

  @override
  Parser failureState() => super.failureState().map((c) {
    final lastSeenSymbol = (c is List && c.length >= 2) ? c[1] : c;
    throw Exception('Invalid syntax, last seen symbol: {$lastSeenSymbol} ');
  });

  @override
  Parser additiveExpression() => super.additiveExpression().map((c) {
    Expression left = c[0];
    for (final item in c[1]) {
      Expression right = item[1];
      if (item[0].value == '+') {
        left = AdditionExpression(left, right);
      } else if (item[0].value == '-') {
        left = SubtractionExpression(left, right);
      } else {
        throw Exception("Unknown additive expression type '${item[0].value}'");
      }
    }
    return left;
  });

  @override
  Parser multiplicativeExpression() => super.multiplicativeExpression().map((c) {
    Expression left = c[0];
    for (final item in c[1]) {
      Expression right = item[1];
      if ((item[0] is List) && (item[0][0].value == '~') && (item[0][1].value == '/')) {
        left = IntegerDivisionExpression(left, right);
      } else if (item[0].value == '*') {
        left = MultiplicationExpression(left, right);
      } else if (item[0].value == '/') {
        left = DivisionExpression(left, right);
      } else if (item[0].value == '%') {
        left = ModuloExpression(left, right);
      } else {
        throw Exception("Unknown multiplicative expression type '${item[0].value}'");
      }
    }
    return left;
  });

  @override
  Parser expressionInParentheses() => super.expressionInParentheses().map((c) => c[1]);

  @override
  Parser unaryExpression() => super.unaryExpression().map((c) {
    if (c is List && c.length == 2) {
      if (c[0].value == '-' || c[0].value == '!') {
        return NegationExpression(c[1]);
      }
    }
    return c;
  });

  @override
  Parser postfixOperatorExpression() => super.postfixOperatorExpression().map((c) {
    if (c[1] == null) return c[0];
    return _createNonNullableConversionExpression(c[0]);
  });

  @override
  Parser conditionalExpression() => super.conditionalExpression().map((c) {
    if (c[1] == null) return c[0];
    return _createConditionalExpression(c[0], c[1][1], c[1][3]);
  });

  @override
  Parser ifNullExpression() => super.ifNullExpression().map((c) {
    Expression expression = c[0];
    for (final item in c[1]) {
      if (item[0].value == '??') {
        expression = IfNullExpression(expression, item[1]);
        continue;
      }
      throw Exception('Unknown if-null expression type');
    }
    return expression;
  });

  @override
  Parser logicalOrExpression() => super.logicalOrExpression().map((c) {
    Expression expression = c[0];
    for (final item in c[1]) {
      if (item[0].value == '||') {
        expression = LogicalOrExpression(expression, item[1]);
        continue;
      }
      throw Exception('Unknown logical-or expression type');
    }
    return expression;
  });

  @override
  Parser logicalAndExpression() => super.logicalAndExpression().map((c) {
    Expression expression = c[0];
    for (final item in c[1]) {
      if (item[0].value == '&&') {
        expression = LogicalAndExpression(expression, item[1]);
        continue;
      }
      throw Exception('Unknown logical-and expression type');
    }
    return expression;
  });

  @override
  Parser equalityExpression() => super.equalityExpression().map((c) {
    Expression left = c[0];
    if (c[1] == null) return left;

    final item = c[1];
    final right = item[1];
    if (item[0].value == '==') {
      left = EqualToExpression(left, right);
    } else if (item[0].value == '!=') {
      left = NegationExpression(EqualToExpression(left, right));
    }
    return left;
  });

  @override
  Parser relationalExpression() => super.relationalExpression().map((c) {
    Expression left = c[0];
    if (c[1] == null) return left;

    final item = c[1];
    final right = item[1];
    if (item[0].value == '<') {
      left = LessThanExpression(left, right);
    } else if (item[0].value == '<=') {
      left = LessThanOrEqualToExpression(left, right);
    } else if (item[0].value == '>') {
      left = LessThanExpression(right, left);
    } else if (item[0].value == '>=') {
      left = LessThanOrEqualToExpression(right, left);
    } else {
      throw Exception("Unknown relational expression type '${item[0].value}'");
    }
    return left;
  });

  @override
  Parser reference() => super.reference().map((values) {
    final resolved = _getDataStore(values[0]);
    var value = resolved.key != "" ? resolved.value[resolved.key] : resolved.value;
    if (value != null) {
      value = value is DataValueNotifier ? value.value : value;
      for (final next in values[1]) {
        if (next[1] != null) {
          // TODO: handle index out of range errors gracefully and provide better error messages
          value = value[next[1] is Expression ? next[1].evaluate() : next[1]];
          value = value is DataValueNotifier ? value.value : value;
        } else {
          value = null;
          break;
        }
      }
    }
    return ConstantExpression(value);
  });

  @override
  Parser integerNumber() => super.integerNumber().flatten().map((c) =>
      ConstantExpression<int>(int.parse(c))
  );

  @override
  Parser doubleNumber() => super.doubleNumber().flatten().map((c) =>
      ConstantExpression<double>(double.parse(c))
  );

  @override
  Parser singleLineString() => super.singleLineString().flatten().map((c) =>
      ConstantExpression<String>(c.substring(1, c.length - 1))
  );

  @override
  Parser functionParameters() => super.functionParameters().map((c) {
    final result = <Expression>[];
    for (var i = 0; i < c[0].length; i++) {
      result.add(c[0][i][0]);
    }
    result.add(c[1]);
    return result;
  });

  @override
  Parser literal() => super.literal().map((c) => c.value);

  @override
  Parser function() => super.function().map((c) {
    return _createFunctionExpression(c[0], c[2] ?? []);
  });

  @override
  Parser TRUE() => super.TRUE().map((c) => ConstantExpression<bool>(c.value == 'true'));

  @override
  Parser FALSE() => super.FALSE().map((c) => ConstantExpression<bool>(c.value != 'false'));

  //===================================
  // private methods
  //===================================

  ConditionalExpression _createConditionalExpression(Expression<bool> condition, Expression trueValue, Expression falseValue) {
    if (trueValue is Expression<int>) {
      return ConditionalExpression<int>(condition, trueValue, falseValue as Expression<int>);
    }
    if (trueValue is Expression<bool>) {
      return ConditionalExpression<bool>(condition, trueValue, falseValue as Expression<bool>);
    }
    if (trueValue is Expression<String>) {
      return ConditionalExpression<String>(condition, trueValue, falseValue as Expression<String>);
    }
    if (trueValue is Expression<double>) {
      return ConditionalExpression<double>(condition, trueValue, falseValue as Expression<double>);
    }
    if (trueValue is Expression<DateTime>) {
      return ConditionalExpression<DateTime>(condition, trueValue, falseValue as Expression<DateTime>);
    }
    if (trueValue is Expression<Duration>) {
      return ConditionalExpression<Duration>(condition, trueValue, falseValue as Expression<Duration>);
    }
    throw Exception('Unknown expression in conditional expression');
  }

  NullableToNonNullableExpression _createNonNullableConversionExpression(Expression value) {
    if (value is Expression<int>) {
      return NullableToNonNullableExpression<int>(value);
    }
    if (value is Expression<int?>) {
      return NullableToNonNullableExpression<int>(value);
    }
    if (value is Expression<bool>) {
      return NullableToNonNullableExpression<bool>(value);
    }
    if (value is Expression<bool?>) {
      return NullableToNonNullableExpression<bool>(value);
    }
    if (value is Expression<String>) {
      return NullableToNonNullableExpression<String>(value);
    }
    if (value is Expression<String?>) {
      return NullableToNonNullableExpression<String>(value);
    }
    if (value is Expression<double>) {
      return NullableToNonNullableExpression<double>(value);
    }
    if (value is Expression<double?>) {
      return NullableToNonNullableExpression<double>(value);
    }
    if (value is Expression<DateTime>) {
      return NullableToNonNullableExpression<DateTime>(value);
    }
    if (value is Expression<DateTime?>) {
      return NullableToNonNullableExpression<DateTime>(value);
    }
    if (value is Expression<Duration>) {
      return NullableToNonNullableExpression<Duration>(value);
    }
    if (value is Expression<Duration?>) {
      return NullableToNonNullableExpression<Duration>(value);
    }
    throw Exception('Unknown expression in conditional expression');
  }

  Expression _createFunctionExpression(String functionName, List<Expression> parameters) {
    if (_functionFactories.containsKey(functionName)) {
      return _functionFactories[functionName]!.createExpression(_parser, parameters);
    }
    final resolved = _getDataStore(functionName);
    final func = resolved.value[resolved.key];
    if (func is Function) {
      return DynamicFunction(func, parameters);
    }
    throw Exception('Unknown function name $functionName');
  }

  /// Gets local or global data depending on the key prefix
  MapEntry<String, Map<String, dynamic>> _getDataStore(String key) {
    if (key == "global") return MapEntry("", globalData);
    if (key.startsWith("global.")) return MapEntry(key.substring(7), globalData);
    return MapEntry(key, data);
  }
}
