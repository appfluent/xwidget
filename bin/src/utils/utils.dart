bool isBlank(String? value) {
  return value == null || value.isEmpty;
}

bool isNotBlank(String? value) {
  return !isBlank(value);
}