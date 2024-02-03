import 'dart:convert';
import 'dart:io';

import 'code_utils.dart';
import 'lines.dart';

const _endComment = '<!-- // end of #space -->';

String applySpaceMacro(File file, String content) {
  var lines = LineSplitter.split(content).toList();
  lines = removeGeneratedBlocks(lines, 'space');
  lines = _generateCodeBlocks(file, lines);
  return lines.join('\n');
}

List<String> _generateCodeBlocks(File file, List<String> lines) {
  var result = Lines();
  lines.read((line, skip) {
    result.add(line);
    if (!skip && line.isMacro('space')) {
      var space = int.tryParse(line.macroContent.split(' ')[1]) ?? 1;
      for (var i = 0; i < space; i++) {
        result.add('');
        result.add('&nbsp;');
      }
      result.add(_endComment);
    }
  });
  return result.data();
}
