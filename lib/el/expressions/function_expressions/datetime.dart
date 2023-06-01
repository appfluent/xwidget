import 'package:intl/intl.dart';

import '../expression.dart';


class DiffDateTimeFunction extends Expression<Duration> {
  final DateTime left;
  final DateTime right;

  DiffDateTimeFunction(this.left, this.right);

  @override
  Duration evaluate() {
    final diff = left.difference(right);
    return (diff < const Duration(microseconds: 0)) ? (-diff) : diff;
  }
}

class FormatDatetimeFunction extends Expression<String> {
  final String format;
  final DateTime dateTime;

  FormatDatetimeFunction(this.format, this.dateTime);

  @override
  String evaluate() {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }
}

class NowFunction extends Expression<DateTime> {
  @override
  DateTime evaluate() => DateTime.now();
}

class NowInUtcFunction extends Expression<DateTime> {
  @override
  DateTime evaluate() => DateTime.now().toUtc();
}

class ToDateTimeFunction extends Expression<DateTime> {
  final dynamic value;

  ToDateTimeFunction(this.value);

  @override
  DateTime evaluate() {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.parse(value);
    return throw Exception('Invalid DateTime value: $value');;
  }
}