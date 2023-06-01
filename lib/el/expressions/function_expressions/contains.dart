import '../expression.dart';


class ContainsFunction extends Expression<bool> {
  final dynamic value;
  final dynamic searchValue;

  ContainsFunction(this.value, this.searchValue);

  @override
  @override
  bool evaluate() {
    if (value == null) return false;
    if (value is String) return value.contains(searchValue.toString());
    if (value is List) return value.contains(searchValue);
    if (value is Set) return value.contains(searchValue);
    throw Exception("Invalid function 'contains' for type '${value.runtimeType}'. Valid types are String, List and Set.");
  }
}

class ContainsKeyFunction extends Expression<bool> {
  final Map? value;
  final dynamic searchValue;

  ContainsKeyFunction(this.value, this.searchValue);

  @override
  @override
  bool evaluate() {
    if (value == null) return false;
    return value!.containsKey(searchValue);
  }
}

class ContainsValueFunction extends Expression<bool> {
  final Map? value;
  final dynamic searchValue;

  ContainsValueFunction(this.value, this.searchValue);

  @override
  @override
  bool evaluate() {
    if (value == null) return false;
    return value!.containsValue(searchValue);
  }
}