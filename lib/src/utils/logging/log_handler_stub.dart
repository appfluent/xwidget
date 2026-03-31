import 'package:logging/logging.dart';

void platformLogHandler(LogRecord record) {
  throw UnsupportedError('Cannot log without dart:io or dart:js_interop');
}
