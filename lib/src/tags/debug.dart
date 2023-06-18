import 'package:xml/xml.dart';

import '../utils/logging.dart';
import '../xwidget.dart';

/// A simple tag that logs a debug message
class DebugTag implements Tag {
  static const _log = CommonLog("DebugTag");

  @override
  String get name => "debug";

  @override
  /// Logs a debug level message.
  ///
  /// Returns null (no children)
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {
    _log.debug(attributes["message"]);
    return null;
  }
}