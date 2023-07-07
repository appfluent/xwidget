import 'package:xml/xml.dart';

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

    final dependenciesScope = attributes["dependenciesScope"];
    final begin = CommonUtils.tryParseInt(element.getAttribute("begin")) ?? 0;
    final end = CommonUtils.tryParseInt(element.getAttribute("end")) ?? 0;
    final step = CommonUtils.tryParseInt(element.getAttribute("step")) ?? 1;
    if (step == 0) throw Exception("<$name> 'step' cannot be zero.");

    final children = Children();
    for (var index = begin; step > 0 ? index < end : index > end; index += step) {
      final deps = XWidget.scopeDependencies(dependencies, dependenciesScope);
      deps[varName] = index;
      final tagChildren = XWidget.inflateXmlElementChildren(element, deps);
      children.addAll(tagChildren);
    }

    return children;
  }
}