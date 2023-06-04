/// TODO: refactor code until we no long need expression classes

abstract class Expression<T> {
  T evaluate();

  static T evaluateValue<T>(dynamic value) {
    if (value is Expression) {
      final result = value.evaluate();
      if (result is T) return result;
    } else if (value is T) {
      return value;
    }
    throw Exception("Unexpected type for $value. Was expecting a subclass of 'Expression<$T>' or '$T'");
  }
}
