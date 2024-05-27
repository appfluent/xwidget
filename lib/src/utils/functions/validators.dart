/// Validator Functions
///
/// Validator functions assert that a condition is true or false and return
/// a bool value.
library;

import 'converters.dart';

bool contains(dynamic value, dynamic searchValue) {
  if (value == null) return false;
  if (value is String) return value.contains(searchValue.toString());
  if (value is List) return value.contains(searchValue);
  if (value is Set) return value.contains(searchValue);
  throw Exception("Invalid type '${value.runtimeType}' for 'contains' "
      "function. Valid types are String, List and Set.");
}

bool containsKey(Map? map, dynamic searchKey) {
  return (map != null) ? map.containsKey(searchKey) : false;
}

bool containsValue(Map? map, dynamic searchValue) {
  return (map != null) ? map.containsValue(searchValue) : false;
}

bool endsWith(String? value, String searchValue) {
  return value?.endsWith(searchValue) == true;
}

bool isBlank(String? value) {
  return value == null || value.trim().isEmpty;
}

bool isEmpty(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.isEmpty;
  if (value is List) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  if (value is Set) return value.isEmpty;
  return false;
}

bool isNotBlank(String? value) {
  return !isBlank(value);
}

bool isNotEmpty(dynamic value) {
  return !isEmpty(value);
}

bool isNull(dynamic value) {
  return value == null;
}

bool isNotNull(dynamic value) {
  return value != null;
}

bool isTrue(dynamic value) {
  return toBool(value) == true;
}

bool isTrueOrNull(dynamic value) {
  return value == null || toBool(value) == true;
}

bool isFalse(dynamic value) {
  return toBool(value) == false;
}

bool isFalseOrNull(dynamic value) {
  return value == null || toBool(value) == false;
}

bool matches(String? value, String regExp) {
  try {
    if (value != null) {
      final regex = RegExp(regExp);
      final matches = regex.allMatches(value);
      for (final match in matches) {
        if (match.start == 0 && match.end == value.length) {
          return true;
        }
      }
    }
    return false;
  } catch (e) {
    throw Exception('Regular expression $regExp is invalid');
  }
}

bool startsWith(String? value, String searchFor) {
  return value?.startsWith(searchFor) == true;
}