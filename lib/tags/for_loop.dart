import 'package:xml/xml.dart';

import '../utils/parsers.dart';
import '../utils/utils.dart';
import '../xwidget.dart';


class ForLoopTag implements Tag {
  @override
  String get name => "forLoop";

  @override
  Children? processTag(XmlElement element, Map<String, dynamic> attributes, Dependencies dependencies) {
    // 'var' is a required attribute
    final varName = attributes["var"];
    if (varName == null || varName.isEmpty) throw Exception("<$name> 'var' attribute is required.");

    final copyDeps = parseBool(element.getAttribute("copyDependencies")) ?? false;
    final begin = tryParseInt(element.getAttribute("begin")) ?? 0;
    final end = tryParseInt(element.getAttribute("end")) ?? 0;
    final step = tryParseInt(element.getAttribute("step")) ?? 1;
    if (step == 0) throw Exception("<$name> 'step' cannot be zero.");

    final children = Children();
    for (var index = begin; step > 0 ? index < end : index > end; index += step) {
      dependencies[varName] = index;
      final tagChildren = XWidget.inflateXmlElementChildren(
        element,
        copyDeps ? dependencies.copy() : dependencies
      );

      // TODO: dispose of Dependencies copies - wrap in 'DisposeOf' widget
      children.addAll(tagChildren);
    }

    // cleanup scope and return results
    dependencies.remove(varName);
    return children;
  }
}