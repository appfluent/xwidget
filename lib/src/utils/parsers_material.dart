/// Material Parsing Functions
///
/// Parsing functions convert Strings to material objects and
/// should begin with the prefix 'parse' and accept a String? argument.
/// They should not be confused with conversion functions.
library;

import 'package:flutter/material.dart';

import '../../xwidget.dart';

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
      default: throw Exception("Problem parsing Alignment value: $value");
    }
  }
  return null;
}

AlignmentDirectional? parseAlignmentDirectional(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case 'topStart': return AlignmentDirectional.topStart;
      case 'topCenter': return AlignmentDirectional.topCenter;
      case 'topEnd': return AlignmentDirectional.topEnd;
      case 'centerStart': return AlignmentDirectional.centerStart;
      case 'center': return AlignmentDirectional.center;
      case 'centerEnd': return AlignmentDirectional.centerEnd;
      case 'bottomStart': return AlignmentDirectional.bottomStart;
      case 'bottomCenter': return AlignmentDirectional.bottomCenter;
      case 'bottomEnd': return AlignmentDirectional.bottomEnd;
      default: throw Exception("Problem parsing AlignmentDirectional "
          "value: $value");
    }
  }
  return null;
}

AlignmentGeometry? parseAlignmentGeometry(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case 'topLeft': return Alignment.topLeft;
      case 'topStart': return AlignmentDirectional.topStart;
      case 'topCenter': return AlignmentDirectional.topCenter;
      case 'topEnd': return AlignmentDirectional.topEnd;
      case 'topRight': return Alignment.topRight;
      case 'centerLeft': return Alignment.centerLeft;
      case 'centerStart': return AlignmentDirectional.centerStart;
      case 'center': return AlignmentDirectional.center;
      case 'centerEnd': return AlignmentDirectional.centerEnd;
      case 'centerRight': return Alignment.centerRight;
      case 'bottomLeft': return Alignment.bottomLeft;
      case 'bottomStart': return AlignmentDirectional.bottomStart;
      case 'bottomCenter': return AlignmentDirectional.bottomCenter;
      case 'bottomEnd': return AlignmentDirectional.bottomEnd;
      case 'bottomRight': return Alignment.bottomRight;
      default: throw Exception("Problem parsing AlignmentGeometry "
          "value: $value");
    }
  }
  return null;
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
        throw Exception("Problem parsing BorderRadius value: $value");
    }
  }
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
      default: throw Exception("Problem parsing Curve value: $value");
    }
  }
  return null;
}

EdgeInsets? parseEdgeInsets(String? value) {
  final doubles = parseListOfDoubles(value);
  if (doubles != null && doubles.isNotEmpty) {
    switch (doubles.length) {
      case 1: return EdgeInsets.all(doubles[0]);
      case 4: return EdgeInsets.fromLTRB(
          doubles[0],
          doubles[1],
          doubles[2],
          doubles[3]
      );
    }
    throw Exception("Problem EdgeInsets value: $value");
  }
  return null;
}

EdgeInsetsGeometry? parseEdgeInsetsGeometry(String? value) {
  return parseEdgeInsets(value);
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

IconData? parseIcon(String? value) {
  if (value == null || value.isEmpty) return null;
  final icon = XWidget.getIcon(value);
  if (icon != null) return icon;
  throw Exception("Problem parsing IconData value: $value");
}

InputBorder? parseInputBorder(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case 'none': return InputBorder.none;
      case 'outline': return const OutlineInputBorder();
      case 'underline': return const UnderlineInputBorder();
      default: throw Exception("Problem parsing InputBorder value: $value");
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

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = <int, Color>{};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

MaterialColor? parseMaterialColor(String? value) {
  final color = parseColor(value);
  return (color != null) ? createMaterialColor(color) : null;
}

WidgetStateProperty<Color>? parseWidgetStateColor(String? value) {
  final color = parseColor(value);
  return (color != null) ? WidgetStateProperty.all<Color>(color) : null;
}

WidgetStateProperty<double>? parseWidgetStateDouble(String? value) {
  final db = value != null ? double.tryParse(value) : null;
  return (db != null) ? WidgetStateProperty.all<double>(db) : null;
}

WidgetStateProperty<EdgeInsetsGeometry>? parseWidgetStateEdgeInsets(
    String? value
) {
  final padding = parseEdgeInsetsGeometry(value);
  return (padding != null)
      ? WidgetStateProperty.all<EdgeInsetsGeometry>(padding)
      : null;
}

WidgetStateProperty<Size>? parseWidgetStateSize(String? value) {
  final size = parseSize(value);
  return (size != null) ? WidgetStateProperty.all<Size>(size) : null;
}

Offset? parseOffset(String? value) {
  final doubles = parseListOfDoubles(value);
  if (doubles != null && doubles.isNotEmpty) {
    switch (doubles.length) {
      case 1: return Offset(doubles[0], doubles[0]);
      case 2: return Offset(doubles[0], doubles[1]);
    }
    throw Exception("Problem parsing Offset value: $value");
  }
  return null;
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
        throw Exception("Problem parsing Radius value: $value");
    }
  }
}

Rect? parseRect(String? value) {
  if (value != null && value.isNotEmpty) {
    var dimensions = value.split(',');
    if (dimensions.length == 4) {
      return Rect.fromLTRB(
          double.parse(dimensions[0]),
          double.parse(dimensions[1]),
          double.parse(dimensions[2]),
          double.parse(dimensions[3])
      );
    }
    throw Exception("Problem parsing Rect from LTRB value: $value");
  }
  return null;
}

Size? parseSize(String? value) {
  if (value != null && value.isNotEmpty) {
    double? width;
    double? height;
    final parts = value.split("x");
    if (parts.length == 1) {
      width = double.tryParse(parts[0]);
      height = width;
    } else if (parts.length == 2) {
      width = parts[0] == "" ? double.infinity : double.tryParse(parts[0]);
      height = parts[1] == "" ? double.infinity : double.tryParse(parts[1]);
    }
    if (width != null && height != null) {
      return Size(width, height);
    }
    throw Exception("Problem parsing Size value: '$value'. Valid formats are "
        "<W>x<H>, <W>x, x<H>, or <one value for W and H>");
  }
  return null;
}

TextDecoration? parseTextDecoration(String? value) {
  if (value != null && value.isNotEmpty) {
    switch (value) {
      case "lineThrough": return TextDecoration.lineThrough;
      case "overline": return TextDecoration.overline;
      case "underline": return TextDecoration.underline;
      case "none": return TextDecoration.none;
      default: throw Exception("Problem parsing TextDecoration value: $value");
    }
  }
  return null;
}

TextInputType? parseTextInputType(String? value) {
  if (value != null && value.isNotEmpty) {
    switch(value) {
      case "datetime": return TextInputType.datetime;
      case "emailAddress": return TextInputType.emailAddress;
      case "multiline": return TextInputType.multiline;
      case "name": return TextInputType.name;
      case "none": return TextInputType.none;
      case "number": return TextInputType.number;
      case "phone": return TextInputType.phone;
      case "streetAddress": return TextInputType.streetAddress;
      case "text": return TextInputType.text;
      case "url": return TextInputType.url;
      case "visiblePassword": return TextInputType.visiblePassword;
      default: throw Exception("Problem parsing TextInputType value: $value");
    }
  }
  return null;
}

VisualDensity? parseVisualDensity(String? value) {
  final doubles = parseListOfDoubles(value);
  if (doubles != null && doubles.isNotEmpty) {
    switch (doubles.length) {
      case 1: return VisualDensity(
        horizontal: doubles[0],
        vertical: doubles[0]
      );
      case 2: return VisualDensity(
        horizontal: doubles[0],
        vertical: doubles[1]
      );
    }
    throw Exception("Problem parsing VisualDensity value: $value");
  }
  return null;
}