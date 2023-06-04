import 'dart:io';

import 'package:analyzer/dart/element/element.dart';

import '../utils/cli_log.dart';
import '../utils/path_resolver.dart';
import '../utils/source_analyzer.dart';
import 'builder.dart';

class ControllerBuilder extends SpecBuilder {
  final ControllerConfig controllerConfig;

  ControllerBuilder(super.config): controllerConfig = config.controllerConfig;

  @override
  Future<BuilderResult> build() async {
    final result = BuilderResult();
    if (_isOkToBuild()) {
      final output = StringBuffer();
      final imports = StringBuffer();
      final registrations = StringBuffer();
      final analyzer = SourceAnalyzer();
      final sourceManifest = await analyzer.getSourceManifest(controllerConfig.sources);
      final libraryElements = await analyzer.getLibraryElements(sourceManifest.paths);

      output.write(buildFileComments());
      imports.write(buildImports([], controllerConfig.imports));

      // build controller registrations
      for (final path in sourceManifest.paths) {
        final library = libraryElements[path];
        if (library != null) {
          for (final element in library.topLevelElements) {
            if (element is ClassElement) {
              for (final interfaceType in element.allSupertypes) {
                if (getInterfaceElementFQN(interfaceType.element) == "package:xwidget/src/custom/controller.dart::Controller") {
                  imports.write(_buildControllerImport(element));
                  registrations.write(_buildRegisterControllerCall(element));
                }
              }
            }
          }
        } else {
          CliLog.warn("Library element not found for path $path.");
        }
      }

      output.write(imports.toString());
      output.writeln();
      output.write(_buildRegisterControllersMethod(registrations.toString()));

      // write output to target
      final targetUri = await PathResolver.relativeToAbsolute(controllerConfig.target);
      final targetFile = await File(targetUri.path).create(recursive: true);
      await targetFile.writeAsString(output.toString());
      result.outputs.add(targetFile);
      CliLog.success("Controllers output to '${controllerConfig.target}'");
    }
    return result;
  }

  String _buildControllerImport(ClassElement element) {
    return "import '${element.source.uri}';\n";
  }

  String _buildRegisterControllersMethod(String registrationCalls) {
    final code = StringBuffer();
    code.write("void registerXWidgetControllers() {\n");
    code.write(registrationCalls);
    code.write("}\n\n");
    return code.toString();
  }

  String _buildRegisterControllerCall(ClassElement element) {
    return "  XWidget.registerControllerFactory(() => ${element.name}());\n";
  }

  bool _isOkToBuild() {
    var ok = controllerConfig.isValid();
    if (controllerConfig.sources.isEmpty) {
      CliLog.success("Skipping controllers. No sources specified.");
      ok = false;
    }
    return ok;
  }
}