import '../../utils/brackets.dart';
import '../../xwidget.dart';
import 'dynamic_function.dart';
import 'expression.dart';

class ReferenceExpression extends Expression<dynamic> {
  final dynamic data;
  final String path;
  final List<dynamic> subPaths;

  ReferenceExpression(this.data, this.path, this.subPaths);

  @override
  dynamic evaluate(Dependencies dependencies) {
    dynamic value = data == null
      ? dependencies.getValue(path)
      : evaluateValue(data, dependencies);

    for (int i = 0; i < subPaths.length && value != null; i++) {
      final next = subPaths[i];
      if (next[0] == ".") {
        if (next[1] is String) {
          value = PathResolution(next[1], false, value).getValue(true);
        } else if (next[1] is List) {
          final func = DynamicFunction(next[1][0], value, next[1][2]);
          value = func.evaluate(dependencies);
        } else {
          throw Exception("Unrecognized reference subpart: ${next[1]}");
        }
      } else if (next[0] == "[" && next[1] is Expression) {
        final index = next[1].evaluate(dependencies);
        value = PathResolution("[$index]", false, value).getValue(true);
      } else {
        throw Exception("Unrecognized reference part: $next");
      }
    }
    return value;
  }
}