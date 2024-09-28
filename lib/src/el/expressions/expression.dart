import '../../xwidget.dart';

abstract class Expression<T> {
  T evaluate(Dependencies dependencies);

  T evaluateValue<T>(dynamic value, Dependencies dependencies) {
    if (value is Expression) {
      final result = value.evaluate(dependencies);
      if (result is T) {
        return result;
      }
    } else if (value is T) {
      return value;
    }
    throw Exception("Unexpected type for $value. Was expecting a subclass"
        " of 'Expression<$T>' or '$T'");
  }
}
