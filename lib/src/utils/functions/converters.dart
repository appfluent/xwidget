/// Conversion Functions
///
/// Conversion functions convert objects/primitives to other objects/primitives
/// and should begin with the prefix 'to' and accept a dynamic argument value.
/// They should not be confused with parsing functions.
library;

import 'dart:ui';

import 'parsers.dart';

 const millisDays = 86400000;
 const millisHours = 3600000;
 const millisMins = 60000;
 const millisSecs = 1000;

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
  throw Exception("Invalid Color value: $value");
}

DateTime? toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return parseDateTime(value);
  throw Exception("Invalid DateTime: value=$value, "
      "type=${value.runtimeType}");
}

int? toDays(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) return value.inDays;

  dynamic valueCopy = value;
  if (valueCopy is String) valueCopy = parseDateTime(valueCopy);
  if (valueCopy is DateTime) return valueCopy.millisecondsSinceEpoch ~/ 86400000;
  throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}

double? toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return parseDouble(value);
  throw Exception('Invalid double value: $value');
}

Duration? toDuration(dynamic value, [String? intUnit]) {
  if (value == null) return null;
  if (value is Duration) return value;
  if (value is String) return parseDuration(value);
  if (value is int) {
    switch (intUnit) {
      case "d":
      case "days": return Duration(days: value);
      case "h":
      case "hours": return Duration(hours: value);
      case "M":
      case "minutes": return Duration(minutes: value);
      case "s":
      case "seconds": return Duration(seconds: value);
      default: return Duration(milliseconds: value);
    }
  }
  throw Exception("Invalid duration format: $value");
}

T? toEnum<T extends Enum>(dynamic value, List<T> values) {
  if (value == null) return null;
  if (value is T) return value;
  if (value is String) return parseEnum(values, value);
  throw Exception("Enum $T doesn't contain the value '$value'. "
      "Valid values are ${values.asNameMap().keys}");
}

int? toHours(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) return value.inHours;

  dynamic valueCopy = value;
  if (valueCopy is String) valueCopy = parseDateTime(valueCopy);
  if (valueCopy is DateTime) return valueCopy.millisecondsSinceEpoch ~/ 3600000;
  throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}

int? toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  if (value is String) return parseInt(value);
  if (value is Color) return value.value;
  return throw Exception('Invalid int value: $value');
}

int? toMillis(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) return value.inMilliseconds;

  dynamic valueCopy = value;
  if (valueCopy is String) valueCopy = parseDateTime(valueCopy);
  if (valueCopy is DateTime) return valueCopy.millisecondsSinceEpoch;
  throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}

int? toMinutes(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) return value.inMinutes;

  dynamic valueCopy = value;
  if (valueCopy is String) valueCopy = parseDateTime(valueCopy);
  if (valueCopy is DateTime) return valueCopy.millisecondsSinceEpoch ~/ 60000;
  throw Exception('Cannot convert ${value.runtimeType} to int: $value');
}

int? toSeconds(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is Duration) return value.inSeconds;

  dynamic valueCopy = value;
  if (valueCopy is String) valueCopy = parseDateTime(valueCopy);
  if (valueCopy is DateTime) return valueCopy.millisecondsSinceEpoch ~/ 1000;
  throw Exception('Cannot convert ${value.runtimeType} to int: $value');
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

//=================================================
// "try" converter functions
//
// They don't throw exceptions if conversion fails.
//=================================================

bool? tryToBool(dynamic value) {
  try {
    return toBool(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

Color? tryToColor(dynamic value) {
  try {
    return toColor(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

DateTime? tryToDateTime(dynamic value) {
  try {
    return toDateTime(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

int? tryToDays(dynamic value) {
  try {
    return toDays(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

double? tryToDouble(dynamic value) {
  try {
    return toDouble(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

Duration? tryToDuration(dynamic value, [String? unit]) {
  try {
    return toDuration(value, unit);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

T? tryToEnum<T extends Enum>(List<T> values, dynamic value) {
  try {
    return toEnum(values, value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

int? tryToHours(dynamic value) {
  try {
    return toHours(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

int? tryToInt(dynamic value) {
  try {
    return toInt(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

int? tryToMillis(dynamic value) {
  try {
    return toMillis(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

int? tryToMinutes(dynamic value) {
  try {
    return toMinutes(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}

int? tryToSeconds(dynamic value) {
  try {
    return toSeconds(value);
  } catch (e) {
    // intentionally ignored
    return null;
  }
}