import 'package:petitparser/petitparser.dart';

import '../utils/model.dart';
import 'expressions/conditional_expression.dart';
import 'expressions/equal_to.dart';
import 'expressions/dynamic.dart';
import 'expressions/if_null.dart';
import 'expressions/less_than.dart';

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
import 'functions.dart';
import 'grammar.dart';

class ELParserDefinition extends ELGrammarDefinition {
  final Map<String, dynamic> data;
  final Map<String, dynamic> globalData;
  late final BuiltInFunctions _builtInFunctions;
  late Parser _parser;

  ELParserDefinition({
    required this.data,
    required this.globalData,
  }) {
    _builtInFunctions = BuiltInFunctions(_getParser);
  }

  @override
  Parser<T> build<T>({
    @Deprecated("Use 'buildFrom(parser)'") Function? start,
    @Deprecated("Use 'buildFrom(parser)'") List<Object> arguments = const []
  }) {
    if (start != null || arguments.isNotEmpty) {
      throw Exception("Build arguments 'start' and 'arguments' not used. Use "
          "'buildFrom(parser)' instead.");
    }
    return _parser = super.build<T>();
  }

  @override
  Parser<T> buildFrom<T>(Parser<T> parser) {
    return _parser = buildFrom<T>(parser);
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
        throw Exception("Unknown multiplicative expression type "
            "'${item[0].value}'");
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
    return NullableToNonNullableExpression(c[0]);
  });

  @override
  Parser conditionalExpression() => super.conditionalExpression().map((c) {
    if (c[1] == null) return c[0];
    return ConditionalExpression(c[0], c[1][1], c[1][3]);
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
  Parser reference() => super.reference().map((reference) {
    final referenceRoot = reference[0];
    final referenceParts = reference[1];
    final resolved = _getDataStore(referenceRoot);
    var value = resolved.key != "" ? resolved.value[resolved.key] : resolved.value;
    if (value != null) {
      // root value is not null
      value = value is ModelValueNotifier ? value.value : value;
      for (final nextParts in referenceParts) {
        // process the remaining parts of the identifier
        final nextKey = nextParts[1];
        if (nextKey != null && value != null) {
          final key = nextKey is Expression ? nextKey.evaluate() : nextKey;
          if (value is List && key is int && key >= value.length) {
            // List index is out of range
            value = null;
            break;
          } else if (value is List && key is! int){
            // List index is not an integer
            throw Exception("Cannot reference List '${resolved.key}' using "
                "non-integer index '$key'.");
          } else {
            // looks good - proceed
            value = value[key];
            value = value is ModelValueNotifier ? value.value : value;
          }
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
  Parser boolTrue() => super.boolTrue().map((c) => ConstantExpression<bool>(c.value == 'true'));

  @override
  Parser boolFalse() => super.boolFalse().map((c) => ConstantExpression<bool>(c.value != 'false'));

  //===================================
  // private methods
  //===================================

  Expression _createFunctionExpression(String functionName, List<Expression> parameters) {
    final resolved = _getDataStore(functionName);
    final func = _builtInFunctions[functionName] ?? resolved.value[resolved.key];
    if (func != null) {
      if (func is Function) {
        return DynamicFunction(func, parameters);
      }
      throw Exception("Not a function: '$functionName'\n$func");
    }
    throw Exception("Function not found: '$functionName'");
  }

  /// Gets local or global data depending on the key prefix
  MapEntry<String, Map<String, dynamic>> _getDataStore(String key) {
    if (key == "global") return MapEntry("", globalData);
    if (key.startsWith("global.")) return MapEntry(key.substring(7), globalData);
    return MapEntry(key, data);
  }

  Parser _getParser() => _parser;
}
