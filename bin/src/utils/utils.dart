bool isEmpty(String? value) {
  return value == null || value.isEmpty;
}

bool isNotEmpty(String? value) {
  return !isEmpty(value);
}

T? parseEnum<T extends Enum>(List<T> values, String? value) {
  if (value == null || value.isEmpty) return null;
  for (final type in values) {
    if (type.name == value) {
      return type;
    }
  }
  throw Exception("Problem parsing enum '$value'. Valid values are "
      "${values.asNameMap().keys}");
}