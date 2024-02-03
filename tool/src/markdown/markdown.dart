import 'dart:io';
import 'package:args/args.dart';

import 'process_file.dart';
import '../../../bin/src/utils/cli_log.dart';


void main(List<String> unparsedArgs) {
  CliLog.info("Markdown Processor (version 0.1.0)");

  final ArgParser parser = ArgParser();
  parser.addFlag("help", abbr: "h", help: "Usage help", negatable: false);
  parser.addOption(
      "file",
      abbr: "f",
      mandatory: true,
      help: "Markdown file to process");

  final args = parser.parse(unparsedArgs);
  if (args["help"] == true) {
    CliLog.info(parser.usage);
    return;
  }

  final file = File(args["file"]);
  processFile(file);
}