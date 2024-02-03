import 'dart:convert';
import 'dart:io';

import 'code_utils.dart';
import 'lines.dart';
import 'process_file.dart';


const _endComment = '<!-- // end of #include -->';

String applyIncludeMacro(File file, String content) {
  var lines = LineSplitter.split(content).toList();
  var result = Lines();

  lines = removeGeneratedBlocks(lines, 'include');

  lines.read((line, skip) {
    result.add(line);

    if (!skip && line.isMacro("include")) {
      var path = line.macroContent.split(' ')[1];
      var includeFile = File('${file.parent.path}/$path');
      if (includeFile.existsSync()) {
        result.addAll(_readIncludeFile(includeFile));
        result.add(_endComment);
      } else {
        throw 'Error in ${file.path}: File to include ${includeFile.path} not found';
      }
    }
  });
  return result.data().join('\n');
}

List<String> _readIncludeFile(File includeFile) {
  var lines = LineSplitter.split(includeFile.readAsStringSync()).toList();

  // Process included file
  lines = LineSplitter
      .split(processContent(includeFile, lines.join('\n')))
      .toList();

  // Remove any macros
  lines = lines.where((line) =>
    !line.isAnyMacro() && !line.isAnyMacroEnd() && line != usageHint
  ).toList();

  return lines;
}
