import 'dart:io';

class CliLog {
  static void info(String msg) => stdout.writeln(msg);
  static void stepSuccess(String msg) => stdout.writeln("\x1B[32m[✓]\x1B[0m $msg");
  static void stepWarn(String msg) => stdout.writeln("\x1B[33m[!]\x1B[0m \x1B[1m$msg\x1B[0m");
  static void stepError(String msg) => stderr.writeln("\x1B[31m[x]\x1B[0m \x1B[1m$msg\x1B[0m");
}