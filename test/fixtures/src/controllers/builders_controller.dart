import 'package:flutter/material.dart';
import 'package:xwidget/xwidget.dart';

class BuilderTestController extends Controller {
  final fruits = ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'];
  final colorNames = ['Red', 'Green', 'Blue', 'Orange'];
  final colors = [
    const Color(0xFFEF5350),
    const Color(0xFF66BB6A),
    const Color(0xFF42A5F5),
    const Color(0xFFFFA726),
  ];

  @override
  void bindDependencies() {
    dependencies["fruits"] = fruits;
    dependencies["colors"] = colors;
    dependencies["colorNames"] = colorNames;
    dependencies["onButtonPressed"] = onButtonPressed;
    dependencies["onTextChanged"] = onTextChanged;
    dependencies["onItemTap"] = onItemTap;
  }

  void onButtonPressed(String message) {
    debugPrint('Button pressed: $message');
  }

  void onTextChanged(String? value) {
    debugPrint('Text changed: $value');
  }

  void onItemTap(int index) {
    debugPrint('Item tapped: ${fruits[index]}');
  }
}