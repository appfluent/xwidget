import '../../xwidget.dart';
import 'expression.dart';

class ModuloExpression extends Expression<dynamic> {
  final dynamic left;
  final dynamic right;

  ModuloExpression(this.left, this.right);

  @override
  dynamic evaluate(Dependencies dependencies) {
    final leftValue = evaluateValue(left, dependencies);
    final rightValue = evaluateValue(right, dependencies);

    // check null conditions
    if (leftValue == null) throw Exception("Dividend cannot be 'null'");
    if (rightValue == null) throw Exception("Cannot divide by 'null'");

    try {
      return leftValue % rightValue;
    } catch(e) {
      throw Exception("Modulo division is not applicable to types "
          "'${leftValue.runtimeType}' and '${rightValue.runtimeType}'");
    }
  }
}
