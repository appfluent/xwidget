import 'package:xml/xml.dart';

import '../utils/logging.dart';
import '../xwidget.dart';


class DebugTag implements Tag {
  static const _log = Log("DebugTag");

  @override
  String get name => "debug";

  @override
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {
    _log.debug(attributes["message"]);
    return null;
  }
}