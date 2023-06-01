import '../expression.dart';


class ToDurationFunction extends Expression<Duration> {
  final validator = RegExp(r'^P(([0-9]+D)?T?([0-9]+H)?([0-9]+M)?([0-9]+S)?)$');
  final regularExpressions = [
    RegExp(r'[0-9]+D'),
    RegExp(r'[0-9]+H'),
    RegExp(r'[0-9]+M'),
    RegExp(r'[0-9]+S')
  ];

  final String value;

  ToDurationFunction(this.value);

  @override
  Duration evaluate() {
    return _convertIso8601DurationToDuration(value);
  }

  Duration _convertIso8601DurationToDuration(String input) {
    final values = List<int>.filled(4, 0);
    if (!validator.hasMatch(input)) {
      throw Exception('Invalid format of duration string');
    }
    final matchedStrings = [
      regularExpressions[0].stringMatch(input),
      regularExpressions[1].stringMatch(input),
      regularExpressions[2].stringMatch(input),
      regularExpressions[3].stringMatch(input)
    ];
    for (var i = 0; i < matchedStrings.length; i++) {
      if ((matchedStrings[i] != null) && (matchedStrings.isNotEmpty)) {
        values[i] = int.parse(matchedStrings[i]!.substring(0, matchedStrings[i]!.length - 1));
      } else {
        values[i] = 0;
      }
    }
    return Duration(
        days: values[0],
        hours: values[1],
        minutes: values[2],
        seconds: values[3]);
  }
}

class DurationInDaysFunctionExpression extends Expression<int> {
  final Duration value;

  DurationInDaysFunctionExpression(this.value);

  @override
  int evaluate() {
    return value.inDays;
  }
}

class DurationInHoursFunctionExpression extends Expression<int> {
  final Duration value;

  DurationInHoursFunctionExpression(this.value);

  @override
  int evaluate() {
    return value.inHours;
  }
}

class DurationInMinutesFunctionExpression extends Expression<int> {
  final Duration value;

  DurationInMinutesFunctionExpression(this.value);

  @override
  int evaluate() {
    return value.inMinutes;
  }
}

class DurationInSecondsFunctionExpression extends Expression<int> {
  final Duration value;

  DurationInSecondsFunctionExpression(this.value);

  @override
  int evaluate() {
    return value.inSeconds;
  }
}