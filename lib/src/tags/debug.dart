import 'package:xml/xml.dart';

import '../../xwidget.dart';

/// A simple tag that logs a debug message
class DebugTag implements Tag {
  static const _log = CommonLog("DebugTag");

  @override
  String get name => "debug";

  /// Logs a debug level message.
  ///
  /// Returns null (no children)
  @override
  Children? processTag(
      XmlElement element,
      Map<String, dynamic> attributes,
      Dependencies dependencies
  ) {
    _log.debug(attributes["message"]);
    return null;
  }
}
