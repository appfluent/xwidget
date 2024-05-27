class XWidgetUtils {
  /// Gets the first child in a list of children or throws an [Exception] if there are multiple children.
  ///
  /// The expected primary use for this method is by inflaters. We want inflaters to fail loudly if it can't render all
  /// of its children. Silently rendering only the first child leads to UI bugs that are difficult to find.
  static dynamic getOnlyChild(String widgetName, List<dynamic> children,[dynamic defaultValue]) {
    if (children.isEmpty) return defaultValue;
    if (children.length > 1) throw Exception("'$widgetName' cannot have multiple children");
    return children[0];
  }

  static String joinStrings(
    List<String> strings, {
    bool trimEachLine = true,
    bool trimResult = true,
    String separator = " ",
  }) {
    final text = StringBuffer();
    for (var i = 0; i < strings.length; i++) {
      text.write(trimEachLine ? strings[i].trim() : strings[i]);
      if (separator.isNotEmpty && i < strings.length) text.write(separator);
    }
    return trimResult ? text.toString().trim() : text.toString();
  }
}