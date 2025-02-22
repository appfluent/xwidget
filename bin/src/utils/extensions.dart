import 'package:analyzer/dart/element/type.dart';

extension StringExt on String {
  String removeTrailingString(String remove) {
    return endsWith(remove) ? substring(0, length - remove.length) : this;
  }

  String capitalizeFirst() {
    return isNotEmpty
        ? substring(0,1).toUpperCase() + substring(1, length)
        : this;
  }
}

extension DartTypeExt on DartType {
  String displayStringWithoutNullability() {
    final str = getDisplayString();
    return str.endsWith("?") || str.endsWith("*")
        ? str.substring(0, str.length - 1)
        : str;
  }
}
