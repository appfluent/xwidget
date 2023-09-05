extension StringExt on String {
  String removeTrailingString(String remove) {
    return endsWith(remove) ? substring(0, length - remove.length) : this;
  }
}
