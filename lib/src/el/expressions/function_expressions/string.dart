import '../expression.dart';


class StartsWithFunction extends Expression<bool> {
  final String value;
  final String searchValue;

  StartsWithFunction(this.value, this.searchValue);

  @override
  bool evaluate() {
    return value.startsWith(searchValue);
  }
}

class EndsWithFunction extends Expression<bool> {
  final String value;
  final String searchValue;

  EndsWithFunction(this.value, this.searchValue);

  @override
  bool evaluate() {
    return value.endsWith(searchValue);
  }
}

class SubstringFunction extends Expression<String> {
  final String value;
  final int start;
  final int end;

  SubstringFunction(this.value, this.start, this.end);

  @override
  String evaluate() {
    final maxEnd = value.length;
    return value.substring(start, end > 0 && end <= maxEnd ? end : maxEnd);
  }
}

class MatchesFunction extends Expression<bool> {
  final String value;
  final String regex;

  MatchesFunction(this.value, this.regex);

  @override
  bool evaluate() {
    return _isFullMatch(value, regex);
  }

  bool _isFullMatch(String value, String regexSource) {
    try {
      final regex = RegExp(regexSource);
      final matches = regex.allMatches(value);
      for (final match in matches) {
        if (match.start == 0 && match.end == value.length) {
          return true;
        }
      }
      return false;
    } catch (e) {
      throw Exception('Regular expression $regexSource is invalid');
    }
  }
}

class ToStringFunction extends Expression<String> {
  final dynamic value;

  ToStringFunction(this.value);

  @override
  String evaluate() {
    return value.toString();
  }
}