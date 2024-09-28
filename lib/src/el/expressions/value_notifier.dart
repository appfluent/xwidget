import 'package:flutter/widgets.dart';

import '../../xwidget.dart';
import 'expression.dart';

class ValueNotifierExpression<T> extends Expression<T> {
  final ValueNotifier<T> value;

  ValueNotifierExpression(this.value);

  @override
  T evaluate(Dependencies dependencies) {
    return value.value;
  }
}
