import 'package:intl/intl.dart';
import 'package:petitparser/core.dart';
import 'package:xwidget/src/utils/parsers.dart';

class BuiltInFunctions {
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
    switch(name) {
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
      case "formatDateTime": return _formatDateTime;
      case "isEmpty": return _isEmpty;
      case "isNotEmpty": return _isNotEmpty;
      case "isNotNull": return _isNotNull;
      case "isNull": return _isNull;
      case "length": return _length;
      case "matches": return _matches;
      case "now": return _now;
      case "nowInUtc": return _nowInUtc;
      case "startsWith": return _startsWith;
      case "substring": return _substring;
      case "toBool": return _toBool;
      case "toDateTime": return _toDateTime;
      case "toDuration": return _toDuration;
      case "toString": return _toString;
      default: return null;
    }
  }

  bool _contains(dynamic value, dynamic searchValue) {
    if (value == null) return false;
    if (value is String) return value.contains(searchValue.toString());
    if (value is List) return value.contains(searchValue);
    if (value is Set) return value.contains(searchValue);
    throw Exception("Invalid function 'contains' for type '${value.runtimeType}'. Valid types are String, List and Set.");
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
      if (result.isSuccess) {
        return result.value.evaluate();
      } else {
        throw Exception("Failed to evaluate '$expression'. ${result.message}");
      }
    }
  }

  String _formatDateTime(String format, DateTime dateTime) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
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

  int _length(dynamic value) {
    if (value is String) return value.length;
    if (value is List) return value.length;
    if (value is Map) return value.length;
    if (value is Set) return value.length;
    throw Exception("Function 'length' is invalid for type '${value.runtimeType}'. Valid types are String, List, Map, and Set.");
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

  DateTime _nowInUtc() => DateTime.now().toUtc();

  bool _startsWith(String value, String searchValue) => value.startsWith(searchValue);

  String _substring(String value, int start, [int end = -1]) {
    final maxEnd = value.length;
    return value.substring(start, end > 0 && end <= maxEnd ? end : maxEnd);
  }

  DateTime _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.parse(value);
    return throw Exception('Invalid DateTime value: $value');
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
            ? int.parse(matchedStrings[i]!.substring(0, matchedStrings[i]!.length - 1)) : 0;
      }
      return Duration(days: values[0], hours: values[1], minutes: values[2], seconds: values[3]);
    }
    throw Exception("Invalid duration format: $value");
  }

  String _toString(dynamic value) => value.toString();
  
  bool _toBool(dynamic value) => parseBool(value) ?? false;
}
