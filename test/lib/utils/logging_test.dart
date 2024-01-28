import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

import '../../../lib/xwidget.dart';

typedef _TestPrinterCallback = Function(Level, String, dynamic, StackTrace?);

class _TestPrinter extends LogPrinter {
  final _TestPrinterCallback callback;

  _TestPrinter(this.callback);

  @override
  List<String> log(LogEvent event) {
    callback(event.level, event.message, event.error, event.stackTrace);
    return [];
  }
}

main() {
  Level? printedLevel;
  String? printedMessage;
  dynamic printedError;
  StackTrace? printedStackTrace;

  setUp(() {
    CommonLog.initialize(
      logger: Logger(
        printer: _TestPrinter((level, message, error, stackTrace) {
          printedLevel = level;
          printedMessage = message;
          printedError = error;
          printedStackTrace = stackTrace;
        }),
    ));
    printedLevel = null;
    printedMessage = null;
    printedError = null;
    printedStackTrace = null;
  });

  test('Test debug logging', () {
    const log = CommonLog("TEST");
    log.debug("log debug test");
    expect(printedLevel, Level.debug);
    expect(printedMessage, "TEST: log debug test");
  });

  test('Test info logging', () {
    const log = CommonLog("TEST");
    log.info("log info test");
    expect(printedLevel, Level.info);
    expect(printedMessage, "TEST: log info test");
  });

  test('Test warn logging', () {
    const log = CommonLog("TEST");
    log.warn("log warn test", "error");
    expect(printedLevel, Level.warning);
    expect(printedError, "error");
    expect(printedMessage, "TEST: log warn test");
  });

  test('Test error logging', () {
    const log = CommonLog("TEST");
    log.error("log error test", "error", StackTrace.current);
    expect(printedLevel, Level.error);
    expect(printedError, "error");
    expect(printedStackTrace != null, true);
    expect(printedMessage, "TEST: log error test");
  });
}