import 'dart:io';

import 'package:logging/logging.dart';

/// A log handler that routes log output to stdout or stderr based on
/// severity.
///
/// Messages at [Level.WARNING] or above are written to stderr; all
/// others are written to stdout. Each message is formatted as:
///
///     LEVEL: TIMESTAMP: LOGGER_NAME: MESSAGE
///
/// Intended for use in CLI tools and server-side Dart applications
/// where platform-level stream separation is needed (e.g. the `xc`
/// CLI). Not suitable for Flutter mobile/web contexts.
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
    stderr.writeln(message);
    if (record.error != null) stderr.writeln(record.error);
    if (record.stackTrace != null) stderr.writeln(record.stackTrace);
  } else {
    stdout.writeln(message);
  }
}
