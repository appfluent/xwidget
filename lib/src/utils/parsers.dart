import 'package:flutter/material.dart';

import '../xwidget.dart';

final _parseDurationRegExp = RegExp(r'^(\d+)(ms|s)$');

double? parseHeight(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value == "infinity") return double.infinity;
  return double.parse(value);
}

double? parseWidth(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value == "infinity") return double.infinity;
  return double.parse(value);
}

bool? parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    if (value.isEmpty) return null;
    switch (value.toLowerCase()) {
      case "true": return true;
      case "false": return false;
    }
  }
  throw Exception("Invalid bool value: $value");
}

Duration? parseDuration(String? value) {
  if (value != null && value.isNotEmpty) {
    final match = _parseDurationRegExp.firstMatch(value);
    if (match != null) {
      final digits = int.parse(match.group(1)!);
      final unit = match.group(2);
      switch (unit) {
        case "ms": return Duration(milliseconds: digits);
        case "s": return Duration(seconds: digits);
        default: throw Exception("Invalid duration unit: $unit");
      }
    }
    throw Exception("Invalid duration value: $value");
  }
  return null;
}

Curve? parseCurve(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case "bounceIn": return Curves.bounceIn;
      case "bounceInOut": return Curves.bounceInOut;
      case "bounceOut": return Curves.bounceOut;
      case "decelerate": return Curves.decelerate;
      case "ease": return Curves.ease;
      case "easeIn": return Curves.easeIn;
      case "easeInBack": return Curves.easeInBack;
      case "easeInCirc": return Curves.easeInCirc;
      case "easeInCubic": return Curves.easeInCubic;
      case "easeInExpo": return Curves.easeInExpo;
      case "easeInOut": return Curves.easeInOut;
      case "easeInOutBack": return Curves.easeInOutBack;
      case "easeInOutCirc": return Curves.easeInOutCirc;
      case "easeInOutCubic": return Curves.easeInOutCubic;
      case "easeInOutCubicEmphasized": return Curves.easeInOutCubicEmphasized;
      case "easeInOutExpo": return Curves.easeInOutExpo;
      case "easeInOutQuad": return Curves.easeInOutQuad;
      case "easeInOutQuart": return Curves.easeInOutQuart;
      case "easeInOutQuint": return Curves.easeInOutQuint;
      case "easeInOutSine": return Curves.easeInOutSine;
      case "easeInQuad": return Curves.easeInQuad;
      case "easeInQuart": return Curves.easeInQuart;
      case "easeInQuint": return Curves.easeInQuint;
      case "easeInSine": return Curves.easeInSine;
      case "easeInToLinear": return Curves.easeInToLinear;
      case "easeOut": return Curves.easeOut;
      case "easeOutBack": return Curves.easeOutBack;
      case "easeOutCirc": return Curves.easeOutCirc;
      case "easeOutCubic": return Curves.easeOutCubic;
      case "easeOutExpo": return Curves.easeOutExpo;
      case "easeOutQuad": return Curves.easeOutQuad;
      case "easeOutQuart": return Curves.easeOutQuart;
      case "easeOutQuint": return Curves.easeOutQuint;
      case "easeOutSine": return Curves.easeOutSine;
      case "elasticIn": return Curves.elasticIn;
      case "elasticInOut": return Curves.elasticInOut;
      case "elasticOut": return Curves.elasticOut;
      case "fastLinearToSlowEaseIn": return Curves.fastLinearToSlowEaseIn;
      case "fastOutSlowIn": return Curves.fastOutSlowIn;
      case "linear": return Curves.linear;
      case "linearToEaseOut": return Curves.linearToEaseOut;
      case "slowMiddle": return Curves.slowMiddle;
      default: throw Exception("Invalid curve value: $value");
    }
  }
  return null;
}

Alignment? parseAlignment(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case 'topLeft': return Alignment.topLeft;
      case 'topCenter': return Alignment.topCenter;
      case 'topRight': return Alignment.topRight;
      case 'centerLeft': return Alignment.centerLeft;
      case 'center': return Alignment.center;
      case 'centerRight': return Alignment.centerRight;
      case 'bottomLeft': return Alignment.bottomLeft;
      case 'bottomCenter': return Alignment.bottomCenter;
      case 'bottomRight': return Alignment.bottomRight;
      default: throw Exception("Invalid alignment value: $value");
    }
  }
  return null;
}

Color? parseColor(String? value) {
  if (value == null || value.isEmpty) return null;

  var argb = value;
  if (argb.startsWith("#")) {
    argb = argb.substring(1, argb.length);
  } else if (argb.startsWith("0x")) {
    argb = argb.substring(2, argb.length);
  }
  if (argb.length == 6) {
    argb = "FF$argb";
  }
  if (argb.length == 8) {
    final colorInt = int.parse(argb, radix: 16);
    return Color(colorInt);
  }
  throw Exception("Invalid color value: $value");
}

TextDecoration? parseTextDecoration(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case "lineThrough": return TextDecoration.lineThrough;
      case "overline": return TextDecoration.overline;
      case "underline": return TextDecoration.underline;
      case "none": return TextDecoration.none;
      default: throw Exception("Invalid text decoration value: $value");
    }
  }
  return null;
}

EdgeInsets? parseEdgeInsets(String? value) {
  final doubles = parseListOfDoubles(value);
  if (doubles != null && doubles.isNotEmpty) {
    switch (doubles.length) {
      case 1: return EdgeInsets.all(doubles[0]);
      case 4: return EdgeInsets.fromLTRB(doubles[0], doubles[1], doubles[2], doubles[3]);
    }
    throw Exception("Invalid visual density value: $value");
  }
  return null;
}

EdgeInsetsGeometry? parseEdgeInsetsGeometry(String? value) {
  return parseEdgeInsets(value);
}

BorderRadius? parseBorderRadius(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  } else if (!value.contains(",")) {
    return BorderRadius.all(parseRadius(value) ?? Radius.zero);
  } else {
    final values = value.split(',');
    switch (values.length) {
      case 2:
        return BorderRadius.vertical(
          top: parseRadius(values[0]) ?? Radius.zero,
          bottom: parseRadius(values[1]) ?? Radius.zero,
        );
      case 4:
        return BorderRadius.only(
          topLeft: parseRadius(values[0]) ?? Radius.zero,
          topRight: parseRadius(values[1]) ?? Radius.zero,
          bottomRight: parseRadius(values[2]) ?? Radius.zero,
          bottomLeft: parseRadius(values[3]) ?? Radius.zero,
        );
      default:
        throw Exception("Invalid border radius '$value'");
    }
  }
}

Radius? parseRadius(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  } else if (!value.contains(",")) {
    final x = double.parse(value.trim());
    return Radius.elliptical(x, x);
  } else {
    final values = value.split(':');
    switch (values.length) {
      case 2:
        final x = double.parse(values[0].trim());
        final y = double.parse(values[1].trim());
        return Radius.elliptical(x, y);
      default:
        throw Exception("Invalid radius '$value'");
    }
  }
}

FontWeight? parseFontWeight(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case "thin":
      case "100":
      case "w100": return FontWeight.w100;
      case "extraLight":
      case "200":
      case "w200": return FontWeight.w200;
      case "light":
      case "300":
      case "w300": return FontWeight.w300;
      case "regular":
      case "normal":
      case "400":
      case 'w400': return FontWeight.w400;
      case "medium":
      case "500":
      case "w500": return FontWeight.w500;
      case "semiBold":
      case "600":
      case 'w600': return FontWeight.w600;
      case "bold":
      case "700":
      case "w700": return FontWeight.w700;
      case "extraBold":
      case "800":
      case "w800": return FontWeight.w800;
      case "black":
      case "900":
      case "w900": return FontWeight.w900;
    }
  }
  return null;
}

Key? parseKey(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value == "unique") return UniqueKey();
  return ValueKey(value);
}

Locale? parseLocale(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  } else if (!value.contains("_")) {
    return Locale(value.toLowerCase(), null);
  } else {
    final parts = value.split("_");
    return Locale(parts[0].toLowerCase(), parts[1].toUpperCase());
  }
}

VisualDensity? parseVisualDensity(String? value) {
  final doubles = parseListOfDoubles(value);
  if (doubles != null && doubles.isNotEmpty) {
    switch (doubles.length) {
      case 1: return VisualDensity(horizontal: doubles[0], vertical: doubles[0]);
      case 2: return VisualDensity(horizontal: doubles[0], vertical: doubles[1]);
    }
    throw Exception("Invalid visual density value: $value");
  }
  return null;
}

Offset? parseOffset(String? value) {
  final doubles = parseListOfDoubles(value);
  if (doubles != null && doubles.isNotEmpty) {
    switch (doubles.length) {
      case 1: return Offset(doubles[0], doubles[0]);
      case 2: return Offset(doubles[0], doubles[1]);
    }
    throw Exception("Invalid offset value: $value");
  }
  return null;
}

List<String>? parseListOfStrings(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  } else if (!value.contains(",")) {
    return [value.trim()];
  } else {
    final strings = <String>[];
    final values = value.split(',');
    for (final string in values) {
      strings.add(string.trim());
    }
    return strings;
  }
}

List<double>? parseListOfDoubles(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  } else if (!value.contains(",")) {
    return [double.parse(value.trim())];
  } else {
    final doubles = <double>[];
    final values = value.split(',');
    for (final val in values) {
      doubles.add(double.parse(val.trim()));
    }
    return doubles;
  }
}

List<int>? parseListOfInts(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  } else if (!value.contains(",")) {
    return [int.parse(value.trim())];
  } else {
    final ints = <int>[];
    final values = value.split(',');
    for (final val in values) {
      ints.add(int.parse(val.trim()));
    }
    return ints;
  }
}

IconData? parseIcon(String? value) {
  if (value == null || value.isEmpty) return null;
  final icon = XWidget.getIcon(value);
  if (icon != null) return icon;
  throw Exception("Invalid icon '$value'.");
}

T? parseEnum<T extends Enum>(List<T> values, String? value) {
  if (value == null || value.isEmpty) return null;
  for (final type in values) {
    if (type.name == value) {
      return type;
    }
  }
  throw Exception("Invalid enum '$value'. Valid values are ${values.asNameMap().keys}");
}

MaterialStateProperty<Color>? parseMaterialStateColor(String? value) {
  final color = parseColor(value);
  return (color != null) ? MaterialStateProperty.all<Color>(color) : null;
}

//=====================================

Rect? parseRect(String? fromLTRBString) {
  if (fromLTRBString == null) {
    return null;
  }
  var strings = fromLTRBString.split(',');
  return Rect.fromLTRB(
      double.parse(strings[0]),
      double.parse(strings[1]),
      double.parse(strings[2]),
      double.parse(strings[3])
  );
}
