/// Miscellaneous Functions
///
library;

import 'package:intl/intl.dart';

import '../extensions.dart';

import 'converters.dart';


enum DurationUnits {
  days("d", 86400000),
  hours("h", 3600000),
  minutes("M", 60000),
  seconds("s", 1000),
  milliseconds("m", 1);

  final String code;
  final int millis;
  const DurationUnits(this.code, this.millis);
}

class DurationFormat {
  final String days;
  final String hours;
  final String minutes;
  final String seconds;
  final String milliseconds;

  const DurationFormat(
    this.days,
    this.hours,
    this.minutes,
    this.seconds,
    this.milliseconds
  );

  String getLabel(DurationUnits unit) {
    switch (unit) {
      case DurationUnits.days: return days;
      case DurationUnits.hours: return hours;
      case DurationUnits.minutes: return minutes;
      case DurationUnits.seconds: return seconds;
      case DurationUnits.milliseconds: return milliseconds;
    }
  }
}

const defaultDurationFormat = DurationFormat(" d"," hr"," min"," sec"," ms");

bool deepEquals(dynamic obj1, dynamic obj2) {
  if (identical(obj1, obj2)) return true;
  if (obj1.runtimeType != obj2.runtimeType) return false;
  if (obj1 is Map && obj2 is Map) {
    // compare maps
    if (obj1.length != obj2.length) return false;
    for (final key in obj1.keys) {
      if (!obj2.containsKey(key)) return false;
      final value1 = obj1[key];
      final value2 = obj2[key];
      if (!deepEquals(value1, value2)) return false;
    }
    return true;
  } else if (obj1 is List && obj2 is List) {
    // compare lists
    if (obj1.length != obj2.length) return false;
    for (int i = 0; i < obj1.length; i++) {
      if (!deepEquals(obj1[i], obj2[i])) return false;
    }
    return true;
  } else if (obj1 is Set && obj2 is Set) {
    // compare sets
    if (obj1.length != obj2.length) return false;
    for (var element in obj1) {
      if (!obj2.contains(element)) return false;
    }
    return true;
  } else {
    // compare all other objects
    return obj1 == obj2;
  }
}

int deepHashCode(dynamic value) {
  if (value is Map) {
    // Compute hash code for maps
    int hash = 0;
    for (var entry in value.entries) {
      int keyHash = entry.key.hashCode;
      int valueHash = deepHashCode(entry.value);

      // Combine hash codes of the key and value
      hash = hash ^ (keyHash * 31 + valueHash);
    }
    return hash;
  } else if (value is List) {
    // Compute hash code for lists
    int hash = 0;
    for (var item in value) {
      hash = hash ^ deepHashCode(item);
    }
    return hash;
  } else if (value is Set) {
    // Compute hash code for sets
    int hash = 0;
    for (var item in value) {
      hash = hash ^ deepHashCode(item);
    }
    return hash;
  } else {
    // Compute hash code for other values
    return value.hashCode;
  }
}

Duration diffDateTime(DateTime left, DateTime right) {
  final diff = left.difference(right);
  return (diff < const Duration(microseconds: 0)) ? (-diff) : diff;
}

dynamic first(dynamic value) {
  if (value is List) return value.first;
  if (value is Map) return value.first();
  if (value is Set) return value.first;
  throw Exception("Function 'first' is invalid for type "
      "'${value.runtimeType}'. Valid types are List, Map, and Set.");
}

String? formatDateTime(String format, dynamic value) {
  if (value == null) return null;
  final dateTime = toDateTime(value);
  return dateTime != null ? DateFormat(format).format(dateTime) : null;
}

String? formatDuration(
    Duration? value, [
    String precision = "s",
    DurationFormat? format = defaultDurationFormat
]) {
  if (value == null) return null;
  String formatted = "";
  int millis = value.inMilliseconds.abs();
  for (final unit in DurationUnits.values) {
    final isLast = unit.code == precision || unit.name == precision;
    final unitCount = millis ~/ unit.millis;
    millis = millis - (unitCount * unit.millis);
    if (format == null) {
      final isMillis = unit == DurationUnits.milliseconds;
      final delimiter= isMillis ? "." : ":";
      if (formatted.isNotEmpty) {
        formatted += delimiter + "$unitCount".padLeft(isMillis ? 3 : 2, "0");
      } else if (isLast) {
        formatted += "0$delimiter${'$unitCount'.padLeft(isMillis ? 3 : 2, '0')}";
      } else if (unitCount > 0) {
        formatted += "$unitCount";
      }
    } else if (unitCount > 0 || isLast) {
      final spacer = formatted.isNotEmpty ? " " : "";
      final label = format.getLabel(unit);
      formatted += "$spacer$unitCount$label";
    }
    if (isLast) break;
  }
  return value.isNegative ? "-$formatted" : formatted;
}

dynamic last(dynamic value) {
  if (value is List) return value.last;
  if (value is Map) return value.last();
  if (value is Set) return value.last;
  throw Exception("Function 'last' is invalid for type "
      "'${value.runtimeType}'. Valid types are List, Map, and Set.");
}

int length(dynamic value) {
  if (value is String) return value.length;
  if (value is List) return value.length;
  if (value is Map) return value.length;
  if (value is Set) return value.length;
  throw Exception("Function 'length' is invalid for type "
      "'${value.runtimeType}'. Valid types are String, List, Map, and Set.");
}

bool mapsEqual(Map a, Map b) {
  if (a.length != b.length) {
    return false;
  }
  for (var key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) {
      return false;
    }
  }
  return true;
}

String? replaceAll(String? value, String regExp, String replacement) {
  if (value == null) return null;
  final regex = RegExp(regExp);
  return value.replaceAll(regex, replacement);
}

String? replaceFirst(String? value, String regExp, String replacement, [int startIndex = 0]) {
  if (value == null) return null;
  final regex = RegExp(regExp);
  return value.replaceFirst(regex, replacement, startIndex);
}

Type typeOf<T>() {
  return T;
}

String? substring(String? value, int start, [int end = -1]) {
  if (value == null) return null;
  final maxEnd = value.length;
  return value.substring(start, end > 0 && end <= maxEnd ? end : maxEnd);
}

String nonNullType(Type type) {
  final typeString = type.toString();
  return typeString.endsWith("?")
      ? typeString.substring(0, typeString.length - 1)
      : typeString;
}

DateTime now() => DateTime.now();

/// Returns this DateTime value in the UTC time zone.
///
/// Returns [this] if it is already in UTC.
/// Otherwise this method is equivalent to:
///
/// ```dart template:expression
/// DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch, isUtc: true)
/// ```
DateTime nowUtc() => DateTime.now().toUtc();