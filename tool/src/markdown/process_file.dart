import 'dart:convert';
import 'dart:io';

import '../utils/cli_log.dart';
import 'code_utils.dart';
import 'include.dart';
import 'space.dart';


const usageHint = "<!-- This file was generated. "
    "Run 'dart run tool/markdown.dart -i doc/README.md -o README.md' "
    "to update this file. -->";

extension on FileSystemEntity {
  bool get isMarkdownFile => this is File && path.toLowerCase().endsWith('.md');
}

void processFile(String inputPath, [String? outputPath]) {
  outputPath ??= inputPath;
  CliLog.info("Processing $inputPath -> $outputPath...");

  final input = File(inputPath);
  final output = File(outputPath);
  final content = input.readAsStringSync();
  final result = processContent(input, content);
  output.writeAsStringSync(result);
}

String processContent(File file, String content) {
  content = applyIncludeMacro(file, content);
  content = applySpaceMacro(file, content);
  content = applyUsageHint(content);
  return content;
}

String applyUsageHint(String content) {
  var lines = LineSplitter.split(content).toList();
  var contentUsesMacros = lines.any((line) => line.isAnyMacro());
  if (contentUsesMacros && lines.first != usageHint) {
    return [usageHint, "", ...lines].join('\n');
  }
  return content;
}
