import 'package:petitparser/core.dart';

import '../../utils/functions/converters.dart';
import '../../utils/functions/math.dart';
import '../../utils/functions/misc.dart';
import '../../utils/functions/validators.dart';
import '../../utils/logging.dart';
import '../../xwidget.dart';
import 'expression.dart';

const _log = CommonLog("ELFunctions");

Function getDynamicFunction(String name, Dependencies dependencies) {
  switch (name) {
    // please maintain alphabetical order
    case "abs": return abs;
    case "ceil": return ceil;
    case "contains": return contains;
    case "containsKey": return containsKey;
    case "containsValue": return containsValue;
    case "diffDateTime": return diffDateTime;
    case "endsWith": return endsWith;
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
    default: {
      final func = dependencies.getValue(name);
      if (func is Function) {
        return func;
      }
    }
  }
  throw Exception("Function '$name' not found.");
}

Function getDynamicFunctionOn(String name, dynamic source) {
  if (source != null) {
    if (source is Map) {
      final func = source[name];
      if (func is Function) {
        return func;
      }
    }
    switch (name) {
      // please maintain alphabetical order
      case "abs": return source.abs;
      case "ceil": return source.ceil;
      case "compareTo": return source.compareTo;
      case "contains": return source.contains;
      case "containsKey": return source.containsKey;
      case "containsValue": return source.containsValue;
      case "difference": return source.difference;
      case "elementAt": return source.elementAt;
      case "endsWith": return source.endsWith;
      case "entries": return source.entries;
      case "first": return () => source.first;
      case "floor": return source.floor;
      case "indexOf": return source.indexOf;
      case "intersection": return source.intersection;
      case "isEmpty": return () => source.isEmpty;
      case "isEven": return () => source.isEven;
      case "isFinite": return () => source.isFinite;
      case "isInfinite": return () => source.isInfinite;
      case "isNaN": return () => source.isNaN;
      case "isNegative": return () => source.isNegative;
      case "isNotEmpty": return () => source.isNotEmpty;
      case "isOdd": return () => source.isOdd;
      case "keys": return () => source.keys;
      case "last": return () => source.last;
      case "lastIndexOf": return source.lastIndexOf;
      case "length": return () => source.length;
      case "matches": return source.matches;
      case "padLeft": return source.padLeft;
      case "padRight": return source.padRight;
      case "replaceAll": return source.replaceAll;
      case "replaceFirst": return source.replaceFirst;
      case "replaceRange": return source.replaceRange;
      case "round": return source.round;
      case "runtimeType": return () => source.runtimetype;
      case "shuffle": return source.shuffle;
      case "single": return () => source.single;
      case "split": return source.split;
      case "startsWith": return source.startsWith;
      case "sublist": return source.sublist;
      case "substring": return source.substring;
      case "toDouble": return source.toDouble;
      case "toInt": return source.toInt;
      case "toList": return source.toList;
      case "toLowerCase": return source.toLowerCase;
      case "toRadixString": return source.toRadixString;
      case "toSet": return source.toSet;
      case "toString": return source.toString;
      case "toUpperCase": return source.toUpperCase;
      case "trim": return source.trim;
      case "trimLeft": return source.trimLeft;
      case "trimRight": return source.trimRight;
      case "truncate": return source.truncate;
      case "union": return source.union;
      case "values": () => source.values;
    }
  }
  throw Exception("Function '$name' not found.");
}

class EvalFunction extends Expression<dynamic> {
  final Expression expression;
  final Parser parser;

  EvalFunction(
    this.expression,
    this.parser,
  );

  @override
  dynamic evaluate(Dependencies dependencies) {
    final exp = evaluateValue(expression, dependencies);
    if (exp.isNotEmpty) {
      final result = parser.parse(exp);
      if (result is Success) {
        return result.value.evaluate(dependencies);
      } else {
        throw Exception("Failed to evaluate '$exp'. ${result.message}");
      }
    }
  }
}

class DynamicFunction extends Expression<dynamic> {
  final String name;
  final dynamic source;
  final List<dynamic>? positionalArgs;
  final Map<Symbol, dynamic>? namedArgs;

  DynamicFunction(
    this.name, [
    this.source,
    this.positionalArgs,
    this.namedArgs,
  ]);

  @override
  dynamic evaluate(Dependencies dependencies) {
    final func = source == null
      ? getDynamicFunction(name, dependencies)
      : getDynamicFunctionOn(name, source);
    final posArgs = _evaluatePositionalArgs(positionalArgs, dependencies);
    return Function.apply(func, posArgs);
  }

  dynamic _evaluatePositionalArgs(
    List<dynamic>? args,
    Dependencies dependencies
  ) {
    final evaluated = [];
    if (args != null) {
      for (final arg in args) {
        evaluated.add(arg is Expression ? arg.evaluate(dependencies) : arg);
      }
    }
    return evaluated;
  }
}