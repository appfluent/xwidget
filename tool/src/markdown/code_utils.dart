import 'lines.dart';

extension LinesReader on List<String> {
  void read(void Function(String line, bool skip) readFn) {
    var skip = false;

    for (var line in this) {
      if (line.isEmbeddedCode) {
        skip = !skip;
      }
      readFn(line, skip);
    }
  }
}

extension CodeExtension on String {
  bool get isEmbeddedCode => trim().startsWith('```');

  bool isMacro(String command) {
    var line = trim().toLowerCase();
    return line.startsWith('<!-- #$command ') && line.endsWith('-->');
  }

  bool isAnyMacro() {
    var line = trim().toLowerCase();
    return line.startsWith('<!-- #') && line.endsWith('-->');
  }

  bool isMacroEnd(String command) {
    return trim() == '<!-- // end of #$command -->';
  }

  bool isAnyMacroEnd() {
    var line = trim().toLowerCase();
    return line.startsWith('<!-- // end of #') && line.endsWith('-->');
  }

  String get macroContent {
    return RegExp(r'<!-- (#.*?) -->').firstMatch(this)?.group(1) ?? '';
  }
}

List<String> removeGeneratedBlocks(List<String> lines, String command) {
  var result = Lines();

  for (var line in lines) {
    result.add(line);

    if (line.isMacroEnd(command)) {
      result.discard();
    } else if (line.isMacro(command)) {
      result.accept();
    }
  }
  return result.data();
}