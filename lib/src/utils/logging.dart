import 'package:logger/logger.dart';


typedef OnMessage = Function(String);
typedef OnError = Function(String, [dynamic, StackTrace?]);

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

  static final _colorRegExp = RegExp("\\{\\{(black|red|green|yellow|blue|magenta|cyan|white|bold|reset)\\}\\}");

  static Logger _logger = _defaultLogger;
  static OnMessage? _onDebug;
  static OnMessage? _onInfo;
  static OnError? _onWarn;
  static OnError? _onError;

  static final _defaultLogger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    output: null, // Use the default LogOutput (-> send everything to console)
    printer: PrettyPrinter(
      methodCount: 0,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
  );

  final String tag;

  // constructors and initializers

  static initialize({
    Logger? logger,
    OnMessage? onDebug,
    OnMessage? onInfo,
    OnError? onWarn,
    OnError? onError,
  }) {
    if (logger != null) {
      _logger = logger;
    }
    _onDebug = onDebug;
    _onInfo = onInfo;
    _onWarn = onWarn;
    _onError = onError;
  }

  const CommonLog([this.tag = ""]);

  // public methods

  debug(dynamic message) {
    var msg = _buildMessage(message);
    _logger.d(msg);
    if (_onDebug != null) {
      _onDebug!(msg);
    }
  }

  info(dynamic message) {
    var msg = _buildMessage(message);
    _logger.i(msg);
    if (_onInfo != null) {
      _onInfo!(msg);
    }
  }

  warn(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    var msg = _buildMessage(message);
    _logger.w(msg, error, stackTrace);
    if (_onWarn != null) {
      _onWarn!(msg, error, stackTrace);
    }
  }

  error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    var msg = _buildMessage(message);
    _logger.e(msg, error, stackTrace);
    if (_onError != null) {
      _onError!(msg, error, stackTrace);
    }
  }

  // private methods

  _buildMessage(dynamic message) {
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
