import 'dart:io';

import 'package:analyzer/dart/element/element.dart';

import '../utils/cli_log.dart';
import '../utils/path_resolver.dart';
import '../utils/source_analyzer.dart';
import 'builder.dart';

class IconsBuilder extends SpecBuilder {
  final IconConfig iconConfig;

  IconsBuilder(super.config): iconConfig = config.iconConfig;

  @override
  Future<void> build() async {
    final output = StringBuffer();
    final registrations = StringBuffer();
    final analyzer = SourceAnalyzer();
    final sourceManifest = await analyzer.getSourceManifest(iconConfig.sources);
    final libraryElements = await analyzer.getLibraryElements(sourceManifest.paths);

    output.write(buildFileComments());
    output.write(buildImports(libraryElements.values, iconConfig.imports));

    // build icon map
    for (final path in sourceManifest.paths) {
      final library = libraryElements[path];
      if (library != null) {
        for (final element in library.topLevelElements) {
          if (element is PropertyAccessorElement) {
            final returnElement = element.returnType.element2;
            if (returnElement is ClassElement) {
              for (final fieldElement in returnElement.fields) {
                if (fieldElement.isConst) {
                  final fieldTypeName = fieldElement.type.getDisplayString(withNullability: false);
                  if (fieldTypeName == "IconData") {
                    registrations.write(_buildRegisterIconCall(returnElement, fieldElement));
                  }
                }
              }
            }
          }
        }
      } else {
        CliLog.stepWarn("Library element not found for path $path.");
      }
    }

    // build icon registration method
    output.write(_buildRegisterIconsMethod(registrations.toString()));

    // write output to target
    final targetUri = await PathResolver.relativeToAbsolute(iconConfig.target);
    final targetFile = await File(targetUri.path).create(recursive: true);
    await targetFile.writeAsString(output.toString());
    CliLog.stepSuccess("Icons output to '${iconConfig.target}'");
  }

  String _buildRegisterIconsMethod(String registrationCalls) {
    final code = StringBuffer();
    code.write("void registerXWidgetIcons() {\n");
    code.write(registrationCalls);
    code.write("}\n\n");
    return code.toString();
  }

  String _buildRegisterIconCall(ClassElement classElement, FieldElement fieldElement) {
    final key = "${classElement.displayName}.${fieldElement.displayName}";
    final value = key;
    return "  XWidget.registerIcon('$key', $value);\n";
  }
}