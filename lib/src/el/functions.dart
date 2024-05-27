import 'package:petitparser/core.dart';

import '../utils/functions/converters.dart';
import '../utils/functions/math.dart';
import '../utils/functions/misc.dart';
import '../utils/functions/validators.dart';
import '../utils/logging.dart';


class BuiltInFunctions {
  static const _log = CommonLog("BuiltInFunctions");

  final Parser Function() _getParser;

  BuiltInFunctions(this._getParser);

  Function? operator [](String name) {
    switch (name) {
      case "abs": return abs;
      case "ceil": return ceil;
      case "contains": return contains;
      case "containsKey": return containsKey;
      case "containsValue": return containsValue;
      case "diffDateTime": return diffDateTime;
      case "endsWith": return endsWith;
      case "eval": return eval;
      case "floor": return floor;
      case "formatDateTime": return formatDateTime;
      case "formatDuration": return formatDuration;
      case "isBlank": return isBlank;
      case "isEmpty": return isEmpty;
      case "isFalse": return isFalse;
      case "isFalseOrNull": return isFalseOrNull;
      case "isNotBlank": return isNotBlank;
      case "isNotEmpty": return isNotEmpty;
      case "isNotNull": return isNotNull;
      case "isNull": return isNull;
      case "isTrue": return isTrue;
      case "isTrueOrNull": return isTrueOrNull;
      case "length": return length;
      case "logDebug": return _log.debug;
      case "matches": return matches;
      case "now": return now;
      case "nowUtc": return nowUtc;
      case "randomDouble": return randomDouble;
      case "randomInt": return randomInt;
      case "replaceAll": return replaceAll;
      case "replaceFirst": return replaceFirst;
      case "round": return round;
      case "startsWith": return startsWith;
      case "substring": return substring;
      case "toBool": return toBool;
      case "toColor": return toColor;
      case "toDateTime": return toDateTime;
      case "toDays": return toDays;
      case "toDouble": return toDouble;
      case "toDuration": return toDuration;
      case "toHours": return toHours;
      case "toInt": return toInt;
      case "toMillis": return toMillis;
      case "toMinutes": return toMinutes;
      case "toSeconds": return toSeconds;
      case "toString": return toString;
      case "tryToBool": return tryToBool;
      case "tryToColor": return tryToColor;
      case "tryToDateTime": return tryToDateTime;
      case "tryToDays": return tryToDays;
      case "tryToDouble": return tryToDouble;
      case "tryToDuration": return tryToDuration;
      case "tryToHours": return tryToHours;
      case "tryToInt": return tryToInt;
      case "tryToMillis": return tryToMillis;
      case "tryToMinutes": return tryToMinutes;
      case "tryToSeconds": return tryToSeconds;
      default: return null;
    }
  }

  dynamic eval(String? value) {
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
}