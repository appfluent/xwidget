import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart';

import '../utils/cli_log.dart';
import '../utils/path_resolver.dart';
import '../utils/source_analyzer.dart';
import 'builder.dart';

class InflaterBuilder extends SpecBuilder {
  static const inflaterDefAnnotation = "InflaterDef";
  static const inflaterTypeParam = "inflaterType";
  static const inflatesOwnChildrenParam = "inflatesOwnChildren";

  final InflaterConfig inflaterConfig;
  final SchemaConfig schemaConfig;

  InflaterBuilder(super.config):
    inflaterConfig = config.inflaterConfig,
    schemaConfig = config.schemaConfig;

  @override
  Future<void> build() async {
    final inflaters = StringBuffer();
    final schemaElements = StringBuffer();
    final initializers = StringBuffer();
    final analyzer = SourceAnalyzer();
    final sourceManifest = await analyzer.getSourceManifest(inflaterConfig.sources);
    final includeManifest = await analyzer.getSourceManifest(inflaterConfig.includes);
    final libraryElements = await analyzer.getLibraryElements([
      ...sourceManifest.paths,
      ...includeManifest.paths
    ]);

    inflaters.write(buildFileComments());
    inflaters.write(buildImports(libraryElements.values, inflaterConfig.imports));
    inflaters.write(_buildIncludeSource(includeManifest));

    // build inflater classes and schema
    for (final path in sourceManifest.paths) {
      final library = libraryElements[path];
      if (library != null) {
        for (final element in library.topLevelElements) {
          if (element is PropertyAccessorElement) {
            final returnElement = element.returnType.element2;
            if (returnElement is ClassElement) {
              final annotations = decodeMetadata(returnElement.metadata);
              for (final constructor in returnElement.constructors) {
                if (!constructor.isPrivate) {
                  final inflater = _buildInflaterClass(returnElement, constructor, annotations);
                  inflaters.write(inflater[0]);
                  initializers.write(inflater[1]);
                  schemaElements.write(_buildSchemaElement(returnElement, constructor, annotations));
                }
              }
            }
          }
        }
      } else {
        CliLog.stepWarn("Library element not found for path $path.");
      }
    }

    // build initializer method for all inflaters
    inflaters.write(_buildInitializerMethod(initializers.toString()));

    // write to inflater target
    final inflaterTargetUri = await PathResolver.relativeToAbsolute(inflaterConfig.target);
    final inflaterTargetFile = await File(inflaterTargetUri.path).create(recursive: true);
    await inflaterTargetFile.writeAsString(inflaters.toString());
    CliLog.stepSuccess("Inflaters output to '${inflaterConfig.target}'");

    // write to schema target
    final schemaTargetUri = await PathResolver.relativeToAbsolute(schemaConfig.target);
    final schemaTargetFile = await File(schemaTargetUri.path).create(recursive: true);
    final schema = await _buildSchema(schemaElements.toString());
    await schemaTargetFile.writeAsString(schema);
    CliLog.stepSuccess("Schema output to '${schemaConfig.target}'");
  }

  //===================================
  // private methods
  //===================================

  String _buildIncludeSource(SourceManifest includes) {
    final code = StringBuffer();
    for (final file in includes.files) {
      final sourceCode = file.readAsLinesSync();
      code.write("// ==> Start include from '${basename(file.path)}'. <==\n\n");
      for (final line in sourceCode) {
        if (!line.trim().startsWith("import ")) {
          code.writeln(line);
        }
      }
      code.write("\n// ==> End include from '${basename(file.path)}'. <==\n\n");
    }
    return code.toString();
  }

  String _buildInflaterInitializer(String className) {
    return "    XWidget.registerInflater($className());\n";
  }

  String _buildInitializerMethod(String initializers) {
    final code = StringBuffer();
    code.write("void registerXWidgetInflaters() {\n");
    code.write(initializers);
    code.write("}\n\n");
    return code.toString();
  }

  List _buildInflaterClass(ClassElement type, ConstructorElement constructor, Map<String, dynamic> annotations) {
    final code = StringBuffer();
    final constructorArgs = StringBuffer();
    final parseCases = StringBuffer();
    final constructorName = constructor.displayName;
    final className = "${constructorName}Inflater".replaceAll(".", "_");
    final isCustomWidget = annotations.containsKey(inflaterDefAnnotation);
    final inflaterType = annotations[inflaterDefAnnotation]?[inflaterTypeParam] ?? constructorName;
    final inflatesOwnChildren = annotations[inflaterDefAnnotation]?[inflatesOwnChildrenParam] ?? false;

    for (final param in constructor.parameters) {
      if (inflaterConfig.isNotExcludedConstructorArg(constructorName, param.name)) {
        final privateAccess = isPrivateAccessParam(param, isCustomWidget);
        constructorArgs.write(_buildConstructorArg(constructorName, param, privateAccess));
        if (schemaConfig.isNotExcludedAttribute(constructorName, param.name) && !privateAccess) {
          parseCases.write(_buildInflaterParseCase(constructorName, param));
        }
      }
    }
    code.write("class $className extends Inflater {\n\n");
    code.write("    @override\n    String get type => '$inflaterType';\n\n");
    code.write("    @override\n    bool get inflatesOwnChildren => $inflatesOwnChildren;\n\n");
    code.write("    @override\n    bool get inflatesCustomWidget => $isCustomWidget;\n\n");
    code.write(_buildInflaterInflateMethod(type.name, constructorName, constructorArgs.toString()));
    code.write(_buildInflaterParseMethod(parseCases.toString()));
    code.write("}\n\n");
    return [code.toString(), _buildInflaterInitializer(className)];
  }

  String _buildConstructorArg(String constructorName, ParameterElement param, bool privateAccess) {
    final code = StringBuffer();
    code.write("            ");
    if (param.isNamed) {
      code.write("${param.name}: ");
    }
    if (param.name == "children") {
      code.write("[...children, ...?attributes['children']]");
    } else if (param.name == "child") {
      final defaultValue = param.isRequired ? "const SizedBox()" : "null";
      code.write("getOnlyChild('$constructorName', children, $defaultValue)");
    } else {
      final attributeValue = "attributes['${privateAccess ? "_" : "" }${param.name}']";
      final defaultValue = inflaterConfig.findConstructorArgDefault(constructorName, param.name, param.defaultValueCode);
      final paramTypeName = param.type.getDisplayString(withNullability: true);
      if (isTypeList(paramTypeName)) {
        final nullable = paramTypeName.endsWith("?");
        final newDefaultValue = defaultValue == null && !nullable ? "[]" : defaultValue;
        code.write("$attributeValue != null ? [...$attributeValue] : $newDefaultValue");
      } else {
        code.write(attributeValue);
        if (defaultValue != null) {
          code.write(" ?? $defaultValue");
        }
      }
    }
    code.write(",\n");
    return code.toString();
  }

  String _buildInflaterParseCase(String constructorName, ParameterElement param) {
    final code = StringBuffer();
    final parser = inflaterConfig.findConstructorArgParser(constructorName, param.name, param.type.toString());
    code.write("            case '${param.name}': ");
    if (parser != null) {
      code.write("return $parser");
    } else if (param.type.element2 is EnumElement) {
      code.write("return parseEnum(${param.type.element2?.name}.values, value)");
    } else {
      code.write("break");
    }
    code.write(";\n");
    return code.toString();
  }

  String _buildInflaterInflateMethod(String returnType, String constructorName, String constructorArgs) {
    final code = StringBuffer();
    code.write("    @override\n");
    code.write("    $returnType? ");
    code.write("inflate(Map<String, dynamic> attributes, List<dynamic> children, String? text) {\n");
    if (constructorArgs.isNotEmpty) {
      code.write("        return $constructorName(\n");
      code.write(constructorArgs);
      code.write("        );\n");
    } else {
      code.write("        return const $constructorName();\n");
    }
    code.write("    }\n\n");
    return code.toString();
  }

  String _buildInflaterParseMethod(String parseCases) {
    final code = StringBuffer();
    code.write("    @override\n");
    code.write("    dynamic parseAttribute(String name, String value) {\n");
    code.write("        switch (name) {\n");
    code.write(parseCases);
    code.write("        }\n");
    code.write("    }\n");
    return code.toString();
  }

  //=============================================
  // schema methods
  // TODO: auto generate element types from enums
  //=============================================

  Future<String> _buildSchema(String elements) async {
    final templateUri = await PathResolver.relativeToAbsolute(schemaConfig.template);
    final templateFile = File(templateUri.path);
    final template = templateFile.readAsStringSync();
    final code = StringBuffer();
    code.write(template.replaceFirst(RegExp("[ \t]*<!--@@inflaters@@-->"), elements));
    return code.toString();
  }

  String _buildSchemaElement(ClassElement type, ConstructorElement constructor, Map<String, dynamic> annotations) {
    final code = StringBuffer();
    final attributes = StringBuffer();
    final constructorName = constructor.displayName;
    final isCustomWidget = annotations.containsKey(inflaterDefAnnotation);
    final inflaterType = annotations[inflaterDefAnnotation]?[inflaterTypeParam] ?? constructorName;

    for (final param in constructor.parameters) {
      if (inflaterConfig.isNotExcludedConstructorArg(constructorName, param.name) &&
          schemaConfig.isNotExcludedAttribute(constructorName, param.name) &&
          !isPrivateAccessParam(param, isCustomWidget)) {
        attributes.write(_buildSchemaAttribute(type, param));
      }
    }
    code.write('    <xs:element name="$inflaterType">\n');
    code.write(_buildSchemaDocumentation(constructor.documentationComment, 8));
    code.write('        <xs:complexType>\n');
    code.write('            <xs:complexContent>\n');
    code.write('                <xs:extension base="objectType">\n');
    code.write(attributes);
    code.write('                </xs:extension>\n');
    code.write('            </xs:complexContent>\n');
    code.write('        </xs:complexType>\n');
    code.write('    </xs:element>\n\n');
    return code.toString();
  }

  String _buildSchemaDocumentation(String? documentation, int indent) {
    final code = StringBuffer();
    final padding = "".padLeft(indent);
    final docs = documentationToMarkdown(documentation);
    if (docs != null && docs.isNotEmpty) {
      code.write('$padding<xs:annotation>\n');
      code.write('$padding    <xs:documentation xml:lang="en">\n');
      code.writeln(docs);
      code.write('$padding    </xs:documentation>\n');
      code.write('$padding</xs:annotation>\n');
    }
    return code.toString();
  }

  String _buildSchemaAttribute(ClassElement type, ParameterElement param) {
    final code = StringBuffer();
    final schemaType = schemaConfig.findAttributeType(param.type.element2?.name);
    final paramDocs = getParameterDocumentation(type, param);
    code.write('                    <xs:attribute name="${param.name}"');
    if (schemaType != null) {
      code.write(' type="$schemaType"');
    }
    if (paramDocs != null && paramDocs.isNotEmpty) {
      code.write(">\n");
      code.write(_buildSchemaDocumentation(paramDocs, 24));
      code.write('                    </xs:attribute>\n');
    } else {
      code.write('/>\n');
    }
    return code.toString();
  }
}
