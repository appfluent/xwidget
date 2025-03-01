import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart';

import '../utils/cli_log.dart';
import '../utils/extensions.dart';
import '../utils/path_resolver.dart';
import '../utils/source_analyzer.dart';
import 'builder.dart';

class InflaterBuilder extends SpecBuilder {
  static const inflaterDefAnnotation = "InflaterDef";
  static const inflaterTypeParam = "inflaterType";
  static const inflatesOwnChildrenParam = "inflatesOwnChildren";

  final InflaterConfig inflaterConfig;
  final SchemaConfig schemaConfig;
  final Map<String, SchemaType> schemaTypes = {};

  InflaterBuilder(super.config) :
    inflaterConfig = config.inflaterConfig,
    schemaConfig = config.schemaConfig;

  @override
  Future<BuilderResult> build() async {
    final result = BuilderResult();
    if (_isOkToBuild()) {
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
      // todo: nested ifs are a little crazy
      for (final path in sourceManifest.paths) {
        final library = libraryElements[path];
        if (library != null) {
          // found source library
          for (final element in library.topLevelElements) {
            if (element is PropertyAccessorElement) {
              final returnType = element.returnType;
              if (returnType.toString() != "InvalidType") {
                // has a known return type i.e. not invalid
                final inflaterTypes = <InflaterType>[];
                if (element.name == "inflaters") {
                  // found a list of inflaters
                  final computedValues = element.variable2?.computeConstantValue()?.toListValue()?.toSet();
                  if (computedValues != null) {
                    for (final computedValue in computedValues) {
                      final typeValue = computedValue.toTypeValue();
                      if (typeValue != null) {
                        final element = typeValue.element;
                        if (element is ClassElement) {
                          final typeArguments = typeValue is InterfaceType ? typeValue.typeArguments : <DartType>[];
                          inflaterTypes.add(InflaterType(element, typeArguments));
                        }
                      }
                    }
                  }
                }

                // process all class elements
                for (final inflaterType in inflaterTypes) {
                  final annotations = decodeMetadata(inflaterType.element.metadata);
                  for (final constructor in inflaterType.element.constructors) {
                    if (!constructor.isPrivate && (!constructor.hasDeprecated || config.allowDeprecated)) {
                      final inflater = _buildInflaterClass(inflaterType, constructor, annotations);
                      inflaters.write(inflater[0]);
                      initializers.write(inflater[1]);
                      schemaElements.write(_buildSchemaElement(inflaterType, constructor, annotations));
                    }
                  }
                }
              } else {
                CliLog.error("InvalidType for property '$element' in '${basename(path)}'");
              }
            }
          }
        } else {
          CliLog.warn("Library element not found for path '$path'");
        }
      }

      // build initializer method for all inflaters
      inflaters.write(_buildInitializerMethod(initializers.toString()));

      // write to inflater target
      final inflaterTargetUri = await PathResolver.relativeToAbsolute(inflaterConfig.target);
      final inflaterTargetFile = await File(inflaterTargetUri.path).create(recursive: true);
      await inflaterTargetFile.writeAsString(inflaters.toString());
      result.outputs.add(inflaterTargetFile);
      CliLog.success("Inflaters output to '${inflaterConfig.target}'");

      // write to schema target
      final schemaTargetUri = await PathResolver.relativeToAbsolute(schemaConfig.target);
      final schemaTargetFile = await File(schemaTargetUri.path).create(recursive: true);
      final schema = await _buildSchema(schemaElements.toString());
      await schemaTargetFile.writeAsString(schema);
      result.outputs.add(schemaTargetFile);
      CliLog.success("Schema output to '${schemaConfig.target}'");

      result.errors = CliLog.errors;
      result.warnings = CliLog.warnings;
    }
    return result;
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

  List _buildInflaterClass(InflaterType type, ConstructorElement constructor, Map<String, dynamic> annotations) {
    final code = StringBuffer();
    final constructorArgs = StringBuffer();
    final parseCases = StringBuffer();
    final constructorName = constructor.displayName;
    final typedConstructorName = _buildTypedConstructorName(type, constructorName);
    final className = "${_buildInflaterName(type, constructorName, "_")}Inflater";
    final isCustomWidget = annotations.containsKey(inflaterDefAnnotation);
    final inflaterKey = annotations[inflaterDefAnnotation]?[inflaterTypeParam] ?? _buildInflaterName(type, constructorName, ".");
    final inflatesOwnChildren = annotations[inflaterDefAnnotation]?[inflatesOwnChildrenParam] ?? false;
    final inflaterReturnType = type.element.name;

    for (final param in constructor.parameters) {
      if (!param.hasDeprecated || config.allowDeprecated) {
        final paramType = param.type.displayStringWithoutNullability();
        if (paramType != "InvalidType") {
          if (inflaterConfig.isNotExcludedConstructorArg(constructorName, param.name)) {
            final privateAccess = isPrivateAccessParam(param, isCustomWidget);
            constructorArgs.write(_buildConstructorArg(constructorName, param, privateAccess));
            if (schemaConfig.isNotExcludedAttribute(constructorName, param.name) && !privateAccess) {
              final paramType = type.resolveParamType(param);
              parseCases.write(_buildInflaterParseCase(constructorName, param.name, paramType));
            }
          }
        } else {
          CliLog.error("InvalidType for param '$param' of class '$type'");
        }
      }
    }
    code.write("class $className extends Inflater {\n\n");
    code.write("    @override\n    String get type => '$inflaterKey';\n\n");
    code.write("    @override\n    bool get inflatesOwnChildren => $inflatesOwnChildren;\n\n");
    code.write("    @override\n    bool get inflatesCustomWidget => $isCustomWidget;\n\n");
    code.write(_buildInflaterInflateMethod(inflaterReturnType, typedConstructorName, constructorArgs.toString()));
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
      code.write("XWidgetUtils.getOnlyChild('$constructorName', children, $defaultValue)");
    } else {
      final attributeValue = "attributes['${privateAccess ? "_" : ""}${param.name}']";
      final defaultValue = inflaterConfig.findConstructorArgDefault(constructorName, param.name) ?? _calcParamDefault(param);
      final paramTypeName = param.type.getDisplayString();
      if (isTypeList(paramTypeName)) {
        final required = isTypeRequired(paramTypeName);
        final newDefaultValue = defaultValue == null && required ? "[]" : defaultValue;
        code.write("$attributeValue != null ? [...$attributeValue] : $newDefaultValue");
      } else if (isTypeMap(paramTypeName)) {
        final required = isTypeRequired(paramTypeName);
        final newDefaultValue = defaultValue == null && required ? "{}" : defaultValue;
        code.write("$attributeValue != null ? {...$attributeValue} : $newDefaultValue");
      } else if (isTypeDouble(paramTypeName)) {
        code.write("toDouble($attributeValue)");
        if (defaultValue != null) {
          code.write(" ?? $defaultValue");
        } else if (isTypeRequired(paramTypeName)) {
          code.write("!");
        }
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

  String? _calcParamDefault(ParameterElement param) {
    String? defaultValueCode = param.defaultValueCode;
    if (defaultValueCode != null) {
      final constValue = param.computeConstantValue();
      final constVariable = constValue?.variable;
      if (constVariable != null) {
        final constVariableValue = constVariable.computeConstantValue();
        final constVariableValueType = constVariableValue?.type;
        if (constVariableValueType != null) {
          if (constVariableValueType.isDartCoreNull) {
            defaultValueCode = null;
          } else if (constVariableValueType.isDartCoreInt) {
            defaultValueCode = constVariableValue!.toIntValue().toString();
          } else if (constVariableValueType.isDartCoreDouble) {
            final doubleValue = constVariableValue!.toDoubleValue();
            defaultValueCode = doubleValue!.isInfinite ? "double.infinity" : doubleValue.toString();
          } else if (constVariableValueType.isDartCoreBool) {
            defaultValueCode = constVariableValue!.toBoolValue().toString();
          } else if (constVariableValueType.isDartCoreString) {
            defaultValueCode = constVariableValue!.toStringValue().toString();
          } else if (defaultValueCode.startsWith("_")) {
            // default is a private variable
            final constExp = _getConstantInitializer(constValue?.variable);
            if (constExp != null && constExp.isNotEmpty) {
              defaultValueCode = constExp;
            }
          }
        }
      }
    }
    return defaultValueCode;
  }

  String? _getConstantInitializer(VariableElement? element) {
    try {
      // expecting a ConstTopLevelVariableElementImpl object
      final dynamic variable = element;

      // expecting an InstanceCreationExpressionImpl object
      final expression = variable.constantInitializer;

      return expression?.toString();
    } on NoSuchMethodError catch (_) {
      // ignore this error because we're hacking the analyzer to retrieve
      // a property that is not exposed by the api.
    }
    return null;
  }

  String _buildInflaterParseCase(String constructorName, String paramName, DartType paramType) {
    final code = StringBuffer();
    final parser = inflaterConfig.findConstructorArgParser(constructorName, paramName, paramType.toString());
    code.write("            case '$paramName': ");
    if (parser != null) {
      code.write("return $parser");
    } else if (paramType.element is EnumElement) {
      code.write("return parseEnum(${paramType.element?.name}.values, value)");
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
    code.write("inflate(Map<String, dynamic> attributes, List<dynamic> children, List<String> text) {\n");
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
    code.write("        return value;\n");
    code.write("    }\n");
    return code.toString();
  }

  bool _isOkToBuild() {
    var ok = inflaterConfig.isValid() && schemaConfig.isValid(inflaterConfig);
    if (inflaterConfig.sources.isEmpty) {
      CliLog.success("Skipping inflaters. No sources specified.");
      ok = false;
    }
    return ok;
  }

  String _buildTypedConstructorName(InflaterType type, String constructorName) {
    final types = type.argumentNames.isNotEmpty ? "<${type.argumentNames.join(',')}>" : "";
    final dotIndex = constructorName.indexOf(".");
    return dotIndex > 0
        ? constructorName.substring(0, dotIndex) + types +
          constructorName.substring(dotIndex, constructorName.length)
        : constructorName + types;
  }

  String _buildInflaterName(InflaterType type, String constructorName, String separator) {
    final types = type.argumentNames.map((e) => e.capitalizeFirst()).join();
    final dotIndex = constructorName.indexOf(".");
    return dotIndex > 0
        ? constructorName.substring(0, dotIndex) + types + separator +
          constructorName.substring(dotIndex + 1, constructorName.length)
        : constructorName + types;
  }

  //=============================================
  // schema methods
  //=============================================

  Future<String> _buildSchema(String elements) async {
    final templateUri = await PathResolver.relativeToAbsolute(schemaConfig.template);
    final templateFile = File(templateUri.path);
    final templateLines = templateFile.readAsLinesSync();
    final code = StringBuffer();
    for (final line in templateLines) {
      if (line.contains("<!--@@enumTypes@@-->")) {
        for (final schemaType in schemaTypes.values) {
          code.write(schemaType.code);
        }
      } else if (line.contains("<!--@@inflaters@@-->")) {
        code.write(elements);
      } else {
        code.write("$line\n");
      }
    }
    return code.toString();
  }

  String _buildSchemaElement(InflaterType type, ConstructorElement constructor, Map<String, dynamic> annotations) {
    final code = StringBuffer();
    final attributes = StringBuffer();
    final constructorName = constructor.displayName;
    final isCustomWidget = annotations.containsKey(inflaterDefAnnotation);
    final inflaterKey = annotations[inflaterDefAnnotation]?[inflaterTypeParam]
        ?? _buildInflaterName(type, constructorName, ".");

    for (final param in constructor.parameters) {
      if ((!param.hasDeprecated || config.allowDeprecated) &&
          inflaterConfig.isNotExcludedConstructorArg(constructorName, param.name) &&
          schemaConfig.isNotExcludedAttribute(constructorName, param.name) &&
          !isPrivateAccessParam(param, isCustomWidget)) {
        final paramType = param.type.element;
        if (paramType is EnumElement && !schemaTypes.containsKey(paramType.name)) {
          _buildSchemaAttributeType(paramType);
        }
        attributes.write(_buildSchemaAttribute(type, param));
      }
    }
    code.write('    <xs:element name="$inflaterKey">\n');
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

  String _buildSchemaAttribute(InflaterType type, ParameterElement param) {
    final code = StringBuffer();
    final schemaType = _getSchemaAttributeType(param);
    final paramDocs = getParameterDocumentation(type.element, param);
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

  void _buildSchemaAttributeType(EnumElement enumElement) {
    final enumName = enumElement.name;
    final schemaTypeName = "${enumName}AttributeType";
    final code = StringBuffer();
    code.write('    <xs:simpleType name="$schemaTypeName">\n');
    code.write('        <xs:union memberTypes="expressionAttributeType">\n');
    code.write('            <xs:simpleType>\n');
    code.write('                <xs:restriction base="xs:string">\n');
    final values = enumElement.getField("values")?.computeConstantValue()?.toListValue();
    if (values != null) {
      for (final enumItem in values) {
        final enumItemName = enumItem.variable?.name;
        code.write('                    <xs:enumeration value="$enumItemName"/>\n');
      }
    }
    code.write('                </xs:restriction>\n');
    code.write('            </xs:simpleType>\n');
    code.write('        </xs:union>\n');
    code.write('    </xs:simpleType>\n\n');
    schemaTypes[enumElement.name] = SchemaType(schemaTypeName, code.toString());
  }

  String? _getSchemaAttributeType(ParameterElement param) {
    final paramType = param.type.element;
    final paramTypeName = paramType?.name;
    return schemaConfig.findAttributeType(paramTypeName) ?? schemaTypes[paramTypeName]?.name;
  }
}

class SchemaType {
  final String name;
  final String code;

  SchemaType(this.name, this.code);
}

class InflaterType<T> {
  final ClassElement element;
  final List<DartType> arguments;
  final List<TypeParameterElement> parameters;
  late final List<String> argumentNames;

  InflaterType(this.element, this.arguments) : parameters = element.typeParameters {
    int dynamicCount = 0;
    final args = <String>[];
    for (final argument in arguments) {
      final name = argument.element?.name;
      if (name != null) {
        if (name == "dynamic") {
          dynamicCount++;
        }
        args.add(name);
      }
    }
    // ignore type arguments if they're all dynamic
    this.argumentNames = dynamicCount < args.length ? args : [];
  }

  DartType resolveParamType(ParameterElement param) {
    final paramType = param.type;
    for (int i=0; i < parameters.length; i++) {
      final typeParam = parameters[i];
      if (typeParam.name == paramType.toString().replaceAll("?", "")) {
        return arguments[i];
      }
    }
    return paramType;
  }
}