import 'package:xml/xml.dart';

import '../utils/functions/converters.dart';
import '../xwidget.dart';

class ForLoopTag implements Tag {
  @override
  String get name => "forLoop";

  @override
  Children? processTag(
      XmlElement element,
      Map<String, dynamic> attributes,
      Dependencies dependencies)
  {
    // 'var' is a required attribute
    final varName = attributes["var"];
    if (varName == null || varName.isEmpty) {
      throw Exception("<$name> 'var' attribute is required.");
    }

    final dependenciesScope = attributes["dependenciesScope"];
    final begin = toInt(element.getAttribute("begin")) ?? 0;
    final end = toInt(element.getAttribute("end")) ?? 0;
    final step = toInt(element.getAttribute("step")) ?? 1;
    if (step == 0) throw Exception("<$name> 'step' cannot be zero.");

    final children = Children();
    for (var index = begin; step > 0 ? index < end : index > end; index += step) {
      final deps = XWidget.scopeDependencies(element, dependencies, dependenciesScope, "copy");
      deps[varName] = index;
      final tagChildren = XWidget.inflateXmlElementChildren(element, deps, excludeText: true);
      children.addAll(tagChildren);
    }
    return children;
  }
}
