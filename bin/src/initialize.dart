import 'dart:io';

import 'package:args/args.dart';

import 'utils/cli_log.dart';
import 'utils/config_loader.dart';
import 'utils/files.dart';

import 'generate.dart' as generate;

const binDir = "xwidget|bin";
const exampleDir = "xwidget|example";

const initDirs = [
  "lib/xwidget/controllers",
  "resources/fragments",
  "resources/values",
];

const initFiles = {
  "$exampleDir/xwidget_config.yaml": "xwidget_config.yaml",
  "$exampleDir/lib/xwidget/icon_spec.dart": "lib/xwidget/icon_spec.dart",
  "$exampleDir/lib/xwidget/inflater_spec.dart": "lib/xwidget/inflater_spec.dart",
  "$exampleDir/resources/values/colors.xml": "resources/values/colors.xml",
  "$exampleDir/resources/values/strings.xml": "resources/values/strings.xml",
};

const newAppFiles = {
  "$exampleDir/lib/xwidget/controllers/app_controller.dart": "lib/xwidget/controllers/app_controller.dart",
  "$exampleDir/resources/fragments/my_app.xml": "resources/fragments/my_app.xml",
};

Future<void> main(List<String> unparsedArgs) async {
  final pubspec = await ConfigLoader.loadYamlDocument("xwidget|pubspec.yaml");
  final version = ConfigLoader.loadToString(pubspec, "version", "<unknown>");
  CliLog.info("XWidget Initializer (version $version)");

  final ArgParser parser = ArgParser();
  parser.addFlag("help", abbr: "h", help: "Usage help", negatable: false);
  parser.addFlag(
      "new-app",
      abbr: "n",
      help: "Sets up a basic XWidget app.",
      negatable: false);

  final args = parser.parse(unparsedArgs);
  if (args["help"] == true) {
    CliLog.info(parser.usage);
    return;
  }

  if (args["new-app"]) {
    initNewApp(version == "<unknown>" ? "" : "^$version");
  } else {
    init();
  }
}

Future<void> init() async {
  await Files.createDirs(initDirs);
  await Files.copyFiles(initFiles);
  await generate.main([]);
}

Future<void> initNewApp(String xwidgetVer) async {
  stdout.write('Overwrite your current project? (Y/n): ');
  final response = stdin.readLineSync();
  if (response == "y" || response == "Y") {
    await Files.createDirs(initDirs);
    await Files.copyFiles(initFiles, true);
    await Files.copyFiles(newAppFiles, true);
    await buildPubspec(xwidgetVer);
    await buildMain();
    await generate.main([]);
  }
}

Future<void> buildPubspec(String xwidgetVer) async {
  final pubspec = await ConfigLoader.loadYamlDocument("pubspec.yaml");
  final name = ConfigLoader.loadToString(pubspec, "name", "untitled");
  final ver = ConfigLoader.loadToString(pubspec, "version", "1.0.0");
  final desc = ConfigLoader.loadToString(pubspec, "description", "A new XWidget project.");
  final sdkVer = ConfigLoader.loadToString(pubspec, "environment.sdk", ">=3.3.4 <4.0.0");
  final lintsVer = ConfigLoader.loadToString(pubspec, "dev_dependencies.flutter_lints", "^3.0.1");

  final template = await Files.readFile("$binDir/res/pubspec_template.yaml");
  final pubspecContents = template
      .replaceAll(r"$project_name", "'$name'")
      .replaceAll(r"$project_description", "'$desc'")
      .replaceAll(r"$project_version", ver)
      .replaceAll(r"$environment_sdk_version", "'$sdkVer'")
      .replaceAll(r"$xwidget_version", xwidgetVer)
      .replaceAll(r"$flutter_lints_version", lintsVer);
  Files.createFile("pubspec.yaml", pubspecContents);
}

Future<void> buildMain() async {
  final main = await Files.readFile("$exampleDir/lib/main.dart");
  final mainContents = main.replaceAll("package:xwidget_example/", "");
  Files.createFile("lib/main.dart", mainContents);
}