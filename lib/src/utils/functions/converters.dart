/// Conversion Functions
///
/// Conversion functions convert objects/primitives to other objects/primitives
/// and should begin with the prefix 'to' and accept a dynamic argument value.
/// They should not be confused with parsing functions.
library;

import 'dart:ui';

import 'parsers.dart';


final _durationValidator = RegExp(r'^P(([0-9]+D)?T?([0-9]+H)?([0-9]+M)?([0-9]+S)?)$');
final _durationMatcher = [
  RegExp(r'[0-9]+D'),
  RegExp(r'[0-9]+H'),
  RegExp(r'[0-9]+M'),
  RegExp(r'[0-9]+S')
];

bool? toBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is double) return value != 0.0;
  if (value is String) return parseBool(value);
  throw Exception("Invalid bool value: $value");
}

Color? toColor(dynamic value) {
  if (value == null) return null;
  if (value is int) return Color(value);
  if (value is String) return parseColor(value);
  throw Exception("Invalid color value: $value");
}

DateTime? toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.parse(value);
  return throw Exception('Invalid DateTime: value=$value, type=${value.runtimeType}');
}

double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.parse(value);
  return throw Exception('Invalid double value: $value');
}

Duration? toDuration(dynamic value) {
  if (value == null) return null;
  if (value is Duration) return value;

  final values = List<int>.filled(4, 0);
  if (_durationValidator.hasMatch(value)) {
    final matchedStrings = [
      _durationMatcher[0].stringMatch(value),
      _durationMatcher[1].stringMatch(value),
      _durationMatcher[2].stringMatch(value),
      _durationMatcher[3].stringMatch(value)
    ];
    for (var i = 0; i < matchedStrings.length; i++) {
      values[i] = (matchedStrings[i] != null && matchedStrings.isNotEmpty)
          ? int.parse(matchedStrings[i]!.substring(0, matchedStrings[i]!.length - 1))
          : 0;
    }
    return Duration(
        days: values[0],
        hours: values[1],
        minutes: values[2],
        seconds: values[3]
    );
  }
  throw Exception("Invalid duration format: $value");
}

int? toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.parse(value);
  if (value is Color) return value.value;
  return throw Exception('Invalid int value: $value');
}

String? toString(dynamic value) {
  if (value == null) return null;
  if (value is Color) {
    return "0x${value.value
        .toRadixString(16)
        .toUpperCase()
        .padLeft(8, "0")}";
  }
  return value.toString();
}

int? toDays(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) value.inDays;
  if (value is DateTime) value.millisecondsSinceEpoch ~/ 86400000;
  return throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}

int? toHours(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) value.inHours;
  if (value is DateTime) value.millisecondsSinceEpoch ~/ 3600000;
  return throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}

int? toMinutes(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) value.inMinutes;
  if (value is DateTime) value.millisecondsSinceEpoch / 60000;
  return throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}

int? toSeconds(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) value.inSeconds;
  if (value is DateTime) value.millisecondsSinceEpoch / 1000;
  return throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}

int? toMillis(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) value.inMilliseconds;
  if (value is DateTime) value.millisecondsSinceEpoch;
  return throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}