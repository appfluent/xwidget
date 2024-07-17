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

String? substring(String? value, int start, [int end = -1]) {
  if (value == null) return null;
  final maxEnd = value.length;
  return value.substring(start, end > 0 && end <= maxEnd ? end : maxEnd);
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