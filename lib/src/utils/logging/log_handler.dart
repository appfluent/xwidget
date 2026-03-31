import 'package:logging/logging.dart';

import 'log_handler_stub.dart'
    if (dart.library.io) 'log_handler_io.dart'
    if (dart.library.js_interop) 'log_handler_web.dart';

void defaultLogHandler(LogRecord record) => platformLogHandler(record);
