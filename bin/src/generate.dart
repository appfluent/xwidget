import 'package:args/args.dart';

import 'builder/builder.dart';
import 'builder/controller_builder.dart';
import 'builder/icons_builder.dart';
import 'builder/inflater_builder.dart';
import 'utils/cli_log.dart';

// TODO: Add a build function to scan fragments and create a list of all active widgets and then compare
//       it to the spec to see which widgets can be dropped from the spec.

const String version = "0.0.13";

void main(List<String> unparsedArgs) async {
  CliLog.info("XWidget Code Generator (version $version)");

  final ArgParser parser = ArgParser();
  parser.addFlag("help", abbr: "h", help: "Usage help", negatable: false);
  parser.addOption("config", abbr: "c", help: "Path to config file", defaultsTo: "xwidget_config.yaml");
  parser.addMultiOption("only",
      help: "Comma separated list of components to generate. Defaults to all components.",
      allowed: ["inflaters", "icons", "controllers"],
      defaultsTo: ["inflaters", "icons", "controllers"]
  );

  final args = parser.parse(unparsedArgs);

  if (args["help"] == true) {
    CliLog.info(parser.usage);
    return;
  }

  // load config files
  final config = BuilderConfig();
  await config.loadConfig("xwidget|res/default_config.yaml");
  await config.loadConfig(args["config"]);

  // build components
  final buildComponents = <String>{}..addAll(args["only"]);
  for (final component in buildComponents) {
    switch (component) {
      case "inflaters": await InflaterBuilder(config).build(); break;
      case "icons": await IconsBuilder(config).build(); break;
      case "controllers": await ControllerBuilder(config).build(); break;
    }
  }

  CliLog.info("Done!");
}
