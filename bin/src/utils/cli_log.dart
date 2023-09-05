class CliLog {
  static int warnings = 0;
  static int errors = 0;

  static void info(String msg) {
    print(msg);
  }

  static void success(String msg) {
    print("\x1B[32m[✓]\x1B[0m $msg");
  }

  static void warn(String msg) {
    warnings++;
    print("\x1B[33m[!]\x1B[0m \x1B[1m$msg\x1B[0m");
  }

  static void error(String msg) {
    errors++;
    print("\x1B[31m[x]\x1B[0m \x1B[1m$msg\x1B[0m");
  }

  static reset() {
    warnings = 0;
    errors = 0;
  }
}
