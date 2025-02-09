import 'package:args/args.dart';

import 'process_file.dart';
import '../../../bin/src/utils/cli_log.dart';


void main(List<String> unparsedArgs) {
  CliLog.info("Markdown Processor (version 0.1.0)");

  final ArgParser parser = ArgParser()
    ..addFlag("help", abbr: "h", help: "Usage help", negatable: false)
    ..addOption('input', abbr: 'i', mandatory: true, help: 'Path to the input file')
    ..addOption('output', abbr: 'o', help: 'Path to the output file');

  final args = parser.parse(unparsedArgs);
  if (args["help"] == true) {
    CliLog.info(parser.usage);
    return;
  }

  processFile(args["input"], args["output"]);
}