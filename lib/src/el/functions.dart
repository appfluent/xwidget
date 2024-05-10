import 'dart:math';

import 'package:intl/intl.dart';
import 'package:petitparser/core.dart';

import '../utils/logging.dart';
import '../utils/parsers.dart';

class BuiltInFunctions {
  static const _log = CommonLog("BuiltInFunctions");

  final _random = Random();
  final Parser Function() _getParser;
  final _durationValidator = RegExp(r'^P(([0-9]+D)?T?([0-9]+H)?([0-9]+M)?([0-9]+S)?)$');
  final _durationMatcher = [
    RegExp(r'[0-9]+D'),
    RegExp(r'[0-9]+H'),
    RegExp(r'[0-9]+M'),
    RegExp(r'[0-9]+S')
  ];

  BuiltInFunctions(this._getParser);

  Function? operator [](String name) {
    switch (name) {
      case "abs": return _abs;
      case "ceil": return _ceil;
      case "contains": return _contains;
      case "containsKey": return _containsKey;
      case "containsValue": return _containsValue;
      case "diffDateTime": return _diffDateTime;
      case "durationInDays": return _durationInDays;
      case "durationInHours": return _durationInHours;
      case "durationInMinutes": return _durationInMinutes;
      case "durationInSeconds": return _durationInSeconds;
      case "durationInMills": return _durationInMills;
      case "endsWith": return _endsWith;
      case "eval": return _eval;
      case "floor": return _floor;
      case "formatDateTime": return _formatDateTime;
      case "isEmpty": return _isEmpty;
      case "isFalse": return _isFalse;
      case "isFalseOrNull": return _isFalseOrNull;
      case "isNotEmpty": return _isNotEmpty;
      case "isNotNull": return _isNotNull;
      case "isNull": return _isNull;
      case "isTrue": return _isTrue;
      case "isTrueOrNull": return _isTrueOrNull;
      case "length": return _length;
      case "logDebug": return _logDebug;
      case "matches": return _matches;
      case "now": return _now;
      case "nowUtc": return _nowUtc;
      case "randomDouble": return _randomDouble;
      case "randomInt": return _randomInt;
      case "replaceAll": return _replaceAll;
      case "replaceFirst": return _replaceFirst;
      case "round": return _round;
      case "startsWith": return _startsWith;
      case "substring": return _substring;
      case "toBool": return _toBool;
      case "toDateTime": return _toDateTime;
      case "toDouble": return _toDouble;
      case "toDuration": return _toDuration;
      case "toInt": return _toInt;
      case "toString": return _toString;
      default: return null;
    }
  }

  num _abs(dynamic value) {
    if (value is int) return value.abs();
    if (value is double) return value.abs();
    if (value is String) return double.parse(value).abs();
    throw Exception("Invalid value '$value' for 'abs' function.");
  }

  int _ceil(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.ceil();
    if (value is String) return double.parse(value).ceil();
    throw Exception("Invalid value '$value' for 'ceil' function.");
  }

  bool _contains(dynamic value, dynamic searchValue) {
    if (value == null) return false;
    if (value is String) return value.contains(searchValue.toString());
    if (value is List) return value.contains(searchValue);
    if (value is Set) return value.contains(searchValue);
    throw Exception("Invalid type '${value.runtimeType}' for 'contains' "
        "function. Valid types are String, List and Set.");
  }

  bool _containsKey(Map? map, dynamic searchKey) {
    return (map != null) ? map.containsKey(searchKey) : false;
  }

  bool _containsValue(Map? map, dynamic searchValue) {
    return (map != null) ? map.containsValue(searchValue) : false;
  }

  Duration _diffDateTime(DateTime left, DateTime right) {
    final diff = left.difference(right);
    return (diff < const Duration(microseconds: 0)) ? (-diff) : diff;
  }

  int _durationInDays(Duration value) => value.inDays;

  int _durationInHours(Duration value) => value.inHours;

  int _durationInMinutes(Duration value) => value.inMinutes;

  int _durationInSeconds(Duration value) => value.inSeconds;

  int _durationInMills(Duration value) => value.inMilliseconds;

  bool _endsWith(String value, String searchValue) => value.endsWith(searchValue);

  dynamic _eval(String? value) {
    final expression = value;
    if (expression != null && expression.isNotEmpty) {
      final result = _getParser().parse(expression);
      if (result is Success) {
        return result.value.evaluate();
      } else {
        throw Exception("Failed to evaluate '$expression'. ${result.message}");
      }
    }
  }

  int _floor(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.floor();
    if (value is String) return double.parse(value).floor();
    throw Exception("Invalid value '$value' for 'floor' function.");
  }

  String _formatDateTime(String format, dynamic dateTime) {
    final formatter = DateFormat(format);
    return formatter.format(_toDateTime(dateTime));
  }

  bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    if (value is Set) return value.isEmpty;
    return false;
  }

  bool _isNotEmpty(dynamic value) => !_isEmpty(value);

  bool _isNull(dynamic value) => value == null;

  bool _isNotNull(dynamic value) => value != null;

  bool _isTrue(dynamic value) => _toBool(value);

  bool _isTrueOrNull(dynamic value) => value == null || _toBool(value);

  bool _isFalse(dynamic value) => !_toBool(value);

  bool _isFalseOrNull(dynamic value) => value == null || !_toBool(value);

  int _length(dynamic value) {
    if (value is String) return value.length;
    if (value is List) return value.length;
    if (value is Map) return value.length;
    if (value is Set) return value.length;
    throw Exception("Function 'length' is invalid for type "
        "'${value.runtimeType}'. Valid types are String, List, Map, and Set.");
  }

  void _logDebug(dynamic message) {
    _log.debug(message);
  }

  bool _matches(String value, String regExp) {
    try {
      final regex = RegExp(regExp);
      final matches = regex.allMatches(value);
      for (final match in matches) {
        if (match.start == 0 && match.end == value.length) {
          return true;
        }
      }
      return false;
    } catch (e) {
      throw Exception('Regular expression $regExp is invalid');
    }
  }

  DateTime _now() => DateTime.now();

  /// Returns this DateTime value in the UTC time zone.
  ///
  /// Returns [this] if it is already in UTC.
  /// Otherwise this method is equivalent to:
  ///
  /// ```dart template:expression
  /// DateTime.fromMicrosecondsSinceEpoch(microsecondsSinceEpoch, isUtc: true)
  /// ```
  DateTime _nowUtc() => DateTime.now().toUtc();

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
  int _randomInt(int max) => _random.nextInt(max);

  /// Generates a non-negative random floating point value uniformly distributed
  /// in the range from 0.0, inclusive, to 1.0, exclusive.
  ///
  /// Example:
  /// ```dart
  /// var doubleValue = Random().nextDouble(); // Value is >= 0.0 and < 1.0.
  /// doubleValue = Random().nextDouble() * 256; // Value is >= 0.0 and < 256.0.
  /// ```
  double _randomDouble() => _random.nextDouble();

  String _replaceAll(String value, String regExp, String replacement) {
    final regex = RegExp(regExp);
    return value.replaceAll(regex, replacement);
  }

  String _replaceFirst(String value, String regExp, String replacement, [int startIndex = 0]) {
    final regex = RegExp(regExp);
    return value.replaceFirst(regex, replacement, startIndex);
  }

  int _round(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return double.parse(value).round();
    throw Exception("Invalid value '$value' for 'round' function.");
  }

  bool _startsWith(String value, String searchFor) => value.startsWith(searchFor);

  String _substring(String value, int start, [int end = -1]) {
    final maxEnd = value.length;
    return value.substring(start, end > 0 && end <= maxEnd ? end : maxEnd);
  }

  DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.parse(value);
    return throw Exception('Invalid DateTime: value=$value, type=${value.runtimeType}');
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return throw Exception('Invalid double value: $value');
  }

  Duration _toDuration(String value) {
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    return throw Exception('Invalid double value: $value');
  }

  String _toString(dynamic value) => value.toString();

  bool _toBool(dynamic value) => parseBool(value) ?? false;
}
