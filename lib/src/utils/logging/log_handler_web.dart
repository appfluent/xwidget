import 'dart:js_interop';

import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

/// A log handler that routes log output to the browser's developer
/// console based on severity.
///
/// Messages at [Level.WARNING] or above are written via `console.error`;
/// all others are written via `console.log`. Each message is formatted
/// as:
///
///     LEVEL: TIMESTAMP: LOGGER_NAME: MESSAGE
///
/// This is the web counterpart to the platform log handler used in CLI
/// and server-side contexts. It uses the `package:web` interop library
/// to access the browser console API.
///
/// Example:
/// ```dart
/// Logger.root.onRecord.listen(platformLogHandler);
/// ```
void platformLogHandler(LogRecord record) {
  final message =
      '${record.level.name}: ${record.time}: '
      '${record.loggerName}: ${record.message}';
  if (record.level >= Level.WARNING) {
    web.console.error(message.toJS);
  } else {
    web.console.log(message.toJS);
  }
}
