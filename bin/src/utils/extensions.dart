extension StringExt on String {
  String removeTrailingString(String remove) {
    return endsWith(remove) ? substring(0, length - remove.length) : this;
  }

  String capitalizeFirst() {
    return this.isNotEmpty
        ? substring(0,1).toUpperCase() + substring(1, length)
        : this;
  }
}
