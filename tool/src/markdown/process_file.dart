import 'dart:convert';
import 'dart:io';

import '../../../bin/src/utils/cli_log.dart';

import 'code_utils.dart';
import 'include.dart';
import 'space.dart';


const usageHint = "<!-- This file includes generated content. "
    "Run 'dart run tool/markdown -f' to update this file. -->";

extension on FileSystemEntity {
  bool get isMarkdownFile => this is File && path.toLowerCase().endsWith('.md');
}

void processFile(File file) {
  CliLog.info("Processing ${file.path}...");
  final content = file.readAsStringSync();
  final result = processContent(file, content);
  file.writeAsStringSync(result);
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
