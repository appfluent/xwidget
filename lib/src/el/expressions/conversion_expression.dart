import 'expression.dart';


class ConversionExpression<TFrom, TTo extends TFrom> extends Expression<TTo> {
  final Expression<TFrom> value;

  ConversionExpression(this.value);

  @override
  TTo evaluate() {
    return value.evaluate() as TTo;
  }
}
