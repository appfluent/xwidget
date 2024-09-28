import '../../xwidget.dart';
import 'expression.dart';

class NullableToNonNullableExpression<T> extends Expression<T> {
  final Expression<T?> value;

  NullableToNonNullableExpression(this.value);

  @override
  T evaluate(Dependencies dependencies) {
    var result = value.evaluate(dependencies);
    if (result == null) {
      throw Exception('Instance of type $T is null and can\'t be converted to non-nullable');
    }
    return result;
  }
}
