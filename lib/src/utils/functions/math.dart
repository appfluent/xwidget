/// Math Functions
///
library;

import 'dart:math';

import 'parsers.dart';


final _random = Random();

num? abs(dynamic value) {
  if (value == null) return null;
  if (value is int) return value.abs();
  if (value is double) return value.abs();
  if (value is String) return parseDouble(value)?.abs();
  throw Exception("Invalid value '$value' for 'abs' function.");
}

int? ceil(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.ceil();
  if (value is String) return parseDouble(value)?.ceil();
  throw Exception("Invalid value '$value' for 'ceil' function.");
}

int? floor(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.floor();
  if (value is String) return parseDouble(value)?.floor();
  throw Exception("Invalid value '$value' for 'floor' function.");
}

/// Generates a non-negative random integer uniformly distributed in the range
/// from 0, inclusive, to [max], exclusive.
///
/// Implementation note: The default implementation supports [max] values
/// between 1 and (1<<32) inclusive.
///
/// Example:
/// ```dart
/// var intValue = Random().nextInt(10); // Value is >= 0 and < 10.
/// intValue = Random().nextInt(100) + 50; // Value is >= 50 and < 150.
/// ```
int randomInt(int max) => _random.nextInt(max);

/// Generates a non-negative random floating point value uniformly distributed
/// in the range from 0.0, inclusive, to 1.0, exclusive.
///
/// Example:
/// ```dart
/// var doubleValue = Random().nextDouble(); // Value is >= 0.0 and < 1.0.
/// doubleValue = Random().nextDouble() * 256; // Value is >= 0.0 and < 256.0.
/// ```
double randomDouble() => _random.nextDouble();

int? round(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return double.parse(value).round();
  throw Exception("Invalid value '$value' for 'round' function.");
}