import 'package:petitparser/petitparser.dart';

class ELGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => (ref0(expression).end()).or(ref0(failureState));

  Parser boolFalse() =>
      ref1(token, 'false');

  Parser boolTrue() =>
      ref1(token, 'true');

  Parser failureState() =>
      (ref0(expression).trim() & ref0(fail).trim()) | ref0(fail).trim();

  Parser fail() => any();

  Parser letterOrUnderscore() =>
      ref0(letter) | ref1(token, '_');

  Parser doubleNumber() =>
      ref0(digit) &
      ref0(digit).star() &
      char('.') &
      ref0(digit) &
      ref0(digit).star();

  Parser integerNumber() =>
      ref0(digit).plus().flatten();

  Parser singleLineString() =>
      char("'") & ref0(stringContent).star() & char("'");

  Parser stringContent() =>
      pattern("^'");

  Parser literal() => ref1(
      token,
      ref0(doubleNumber) | ref0(integerNumber) | ref0(boolTrue) | ref0(boolFalse) | ref0(singleLineString)
  );

  Parser identifier() =>
      (ref0(letterOrUnderscore) &
      (ref0(letterOrUnderscore) | ref0(digit)).star()).flatten();

  Parser reference() =>
      ref0(identifier) &
      (ref0(arrayReference) | (char('.') & ref0(identifier))).star();

  Parser arrayReference() =>
      char('[') &
      (ref0(expression) | ref0(reference)) &
      char(']');

  Parser function() =>
      ref0(identifier).flatten() &
      ref1(token, '(') &
      ref0(functionParameters).optional() &
      ref1(token, ')');

  Parser functionParameters() =>
      (ref0(expression) & ref1(token, ',')).star() & ref0(expression);

  Parser additiveOperator() => ref1(token, '+') | ref1(token, '-');

  Parser relationalOperator() =>
      ref1(token, '>=') | ref1(token, '>') | ref1(token, '<=') | ref1(token, '<');

  Parser equalityOperator() => ref1(token, '==') | ref1(token, '!=');

  Parser multiplicativeOperator() =>
      ref1(token, '*') |
      ref1(token, '/') |
      ref1(token, '~') & ref1(token, '/') |
      ref1(token, '%');

  Parser unaryNegateOperator() => ref1(token, '-') | ref1(token, '!');

  Parser expressionInParentheses() =>
      ref1(token, '(') & ref0(expression) & ref1(token, ')');

  Parser expression() => ref0(conditionalExpression);

  Parser conditionalExpression() =>
      ref0(ifNullExpression) &
      (ref1(token, '?') & ref0(expression) & ref1(token, ':') & ref0(expression)).optional();

  Parser ifNullExpression() =>
      ref0(logicalOrExpression) &
      (ref1(token, '??') & ref0(logicalOrExpression)).star();

  Parser logicalOrExpression() =>
      ref0(logicalAndExpression) &
      (ref1(token, '||') & ref0(logicalAndExpression)).star();

  Parser logicalAndExpression() =>
      ref0(equalityExpression) &
      (ref1(token, '&&') & ref0(equalityExpression)).star();

  Parser equalityExpression() =>
      ref0(relationalExpression) &
      (ref0(equalityOperator) & ref0(relationalExpression)).optional();

  Parser relationalExpression() =>
      ref0(additiveExpression) &
      (ref0(relationalOperator) & ref0(additiveExpression)).optional();

  Parser additiveExpression() =>
      ref0(multiplicativeExpression) &
      (ref0(additiveOperator) & ref0(multiplicativeExpression)).star();

  Parser multiplicativeExpression() =>
      ref0(postfixOperatorExpression) &
      (ref0(multiplicativeOperator) & ref0(postfixOperatorExpression)).star();

  Parser postfixOperatorExpression() =>
      ref0(unaryExpression) & (char('!').seq(char('=').not())).optional();

  Parser unaryExpression() =>
      ref0(literal) |
      ref0(expressionInParentheses) |
      ref0(function) |
      ref0(reference) |
      ref0(unaryNegateOperator) & ref0(unaryExpression);

  Parser token(Object input) {
    if (input is Parser) {
      return input.token().trim();
    } else if (input is String) {
      return token(input.length == 1 ? char(input) : string(input));
    } else if (input is Parser Function()) {
      return token(ref0(input));
    }
    throw ArgumentError.value(input, 'invalid token parser');
  }
}
