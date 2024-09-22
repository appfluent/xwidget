import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart';

import '../utils/cli_log.dart';
import '../utils/path_resolver.dart';
import '../utils/source_analyzer.dart';
import 'builder.dart';

class IconsBuilder extends SpecBuilder {
  final IconConfig iconConfig;

  IconsBuilder(super.config) : iconConfig = config.iconConfig;

  @override
  Future<BuilderResult> build() async {
    final result = BuilderResult();
    if (_isOkToBuild()) {
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
              final returnType = element.returnType;
              if (returnType.toString() != "InvalidType") {
                // has a known return type
                final classElements = <ClassElement>[];
                if (element.name == "icons") {
                  // found a list of icons
                  final icons = element.variable.computeConstantValue()?.toListValue();
                  if (icons != null) {
                    for (final icon in icons) {
                      final variable = icon.variable;
                      final enclosingElement = variable?.enclosingElement;
                      if (variable != null && enclosingElement != null) {
                        final iconType = icon.type?.getDisplayString(withNullability: false);
                        if (iconType == "IconData") {
                          registrations.write(_buildRegisterIconCall(enclosingElement.displayName, variable.displayName));
                        } else {
                          CliLog.warn("Skipped icon. Expected icon item to be of type 'IconData', but found '$iconType'");
                        }
                      } else {
                        CliLog.warn("Skipped icon. Expected icon item to be a member of a class e.i. 'Icons.add' or "
                            "something similar, but found '$icon'");
                      }
                    }
                  }
                } else if (element.name == "iconSets") {
                  // found a list of icon sets
                  final iconSets = element.variable.computeConstantValue()?.toListValue();
                  if (iconSets != null) {
                    for (final iconSet in iconSets) {
                      final element = iconSet.toTypeValue()?.element;
                      if (element is ClassElement) classElements.add(element);
                    }
                  }
                } else {
                  // found individual icon set const
                  final returnElement = returnType.element;
                  if (returnElement is ClassElement) classElements.add(returnElement);
                }

                // process all class elements
                for (final classElement in classElements) {
                  for (final fieldElement in classElement.fields) {
                    if (fieldElement.isConst) {
                      final fieldTypeName = fieldElement.type.getDisplayString(withNullability: false);
                      if (fieldTypeName == "IconData") {
                        registrations.write(_buildRegisterIconCall(classElement.displayName, fieldElement.displayName));
                      }
                    }
                  }
                }
              } else {
                CliLog.error("InvalidType for property '$element' in '${basename(path)}'");
              }
            }
          }
        } else {
          CliLog.warn("Library element not found for path $path.");
        }
      }

      if (registrations.isNotEmpty) {
        // build icon registration method
        output.write(_buildRegisterIconsMethod(registrations.toString()));

        // write output to target
        final targetUri = await PathResolver.relativeToAbsolute(iconConfig.target);
        final targetFile = await File(targetUri.path).create(recursive: true);
        await targetFile.writeAsString(output.toString());
        result.outputs.add(targetFile);
        CliLog.success("Icons output to '${iconConfig.target}'");
      } else {
        CliLog.success("Skipping icons. No icons found in sources.");
      }

      result.errors = CliLog.errors;
      result.warnings = CliLog.warnings;
    }
    return result;
  }

  String _buildRegisterIconsMethod(String registrationCalls) {
    final code = StringBuffer();
    code.write("void registerXWidgetIcons() {\n");
    code.write(registrationCalls);
    code.write("}\n\n");
    return code.toString();
  }

  String _buildRegisterIconCall(String className, String fieldName) {
    final key = "$className.$fieldName";
    final value = key;
    return "  XWidget.registerIcon('$key', $value);\n";
  }

  bool _isOkToBuild() {
    var ok = iconConfig.isValid();
    if (iconConfig.sources.isEmpty) {
      CliLog.success("Skipping icons. No sources specified.");
      ok = false;
    }
    return ok;
  }
}
