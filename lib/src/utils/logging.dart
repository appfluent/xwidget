import 'package:logger/logger.dart' hide FileOutput;

typedef CommonLogCallback = bool Function(
    LogLevel,
    dynamic,
    [dynamic, StackTrace?]
);

enum LogLevel { debug, info, warn, error }

/// A simple wrapper around [Logger].
///
/// Adds these features:
/// 1. Custom styling by parsing predefined style tags in the message.
/// 2. Adds a callback BEFORE calling the filter's shouldLog method. This
///    allows the callback to decide if the message should be logged. The
///    specific use case in mind is with Firebase. In production, you may
///    want to continue to log to Crashlytics, but not to the console.
///
/// Style tags:
///   black: {{black}}
///   red: {{red}}
///   green: {{green}}
///   yellow: {{yellow}}
///   blue: {{blue}}
///   magenta: {{magenta}}
///   cyan: {{cyan}}
///   white: {{white}}
///   bold: {{bold}}
///   reset: {{reset}}
class CommonLog {
  static const black = "{{black}}";
  static const red = "{{red}}";
  static const green = "{{green}}";
  static const yellow = "{{yellow}}";
  static const blue = "{{blue}}";
  static const magenta = "{{magenta}}";
  static const cyan = "{{cyan}}";
  static const white = "{{white}}";

  static const bold = "{{bold}}";
  static const reset = "{{reset}}";

  // colors
  static const _black = "\x1B[30m";
  static const _red = "\x1B[31m";
  static const _green = "\x1B[32m";
  static const _yellow = "\x1B[33m";
  static const _blue = "\x1B[34m";
  static const _magenta = "\x1B[35m";
  static const _cyan = "\x1B[36m";
  static const _white = "\x1B[37m";

  static const _bold = "\u001b[1m";
  static const _reset = "\x1B[0m";

  static final _colorRegExp = RegExp(
    "\\{\\{(black|red|green|yellow|blue|magenta|cyan|white|bold|reset)\\}\\}"
  );

  static Logger _logger = _defaultLogger;
  static CommonLogCallback? _callback;

  static final _defaultLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
  );

  final String tag;

  // constructors and initializers

  /// Initializes CommonLog with a preconfigured [Logger] and callback function.
  static void initialize({Logger? logger, CommonLogCallback? callback}) {
    if (logger != null) {
      _logger = logger;
    }
    if (callback != null) {
      _callback = callback;
    }
  }

  /// Creates an instance of CommonLog with an optional tag
  ///
  /// The tag is prepended to all log messages.
  const CommonLog([this.tag = ""]);

  // public methods

  /// Log a [message] at level [LogLevel.debug].
  void debug(dynamic message) {
    final msg = _buildMessage(message);
    if (_callback == null || _callback!(LogLevel.debug, msg)) {
      _logger.d(msg);
    }
  }

  /// Log a [message] at level [LogLevel.info].
  void info(dynamic message) {
    final msg = _buildMessage(message);
    if (_callback == null || _callback!(LogLevel.info, msg)) {
      _logger.i(msg);
    }
  }

  /// Log a [message] at level [LogLevel.warn].
  void warn(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final msg = _buildMessage(message);
    if (_callback==null || _callback!(LogLevel.warn, msg, error, stackTrace)) {
      _logger.w(msg, error: error, stackTrace: stackTrace);
    }
  }

  /// Log a [message] at level [LogLevel.error].
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final msg = _buildMessage(message);
    if (_callback==null || _callback!(LogLevel.error, msg, error, stackTrace)) {
      _logger.e(msg, error: error, stackTrace: stackTrace);
    }
  }

  // private methods

  String? _buildMessage(dynamic message) {
    if (message == null) return null;

    final str = message.toString();
    final msg = str.replaceAllMapped(_colorRegExp, (Match match) {
      switch (match[0]) {
        case black: return _black;
        case red: return _red;
        case green: return _green;
        case yellow: return _yellow;
        case blue: return _blue;
        case magenta: return _magenta;
        case cyan: return _cyan;
        case white: return _white;
        case bold: return _bold;
        case reset: return _reset;
        default: return match[0] ?? "";
      }
    });
    return "$tag: $msg";
  }
}
