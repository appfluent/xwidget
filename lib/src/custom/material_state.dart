import 'package:flutter/material.dart';


class MaterialStatePropertyOf<T> extends MaterialStateProperty<T> {
  final T primary;
  final T? hovered;
  final T? focused;
  final T? pressed;
  final T? dragged;
  final T? selected;
  final T? scrolledUnder;
  final T? disabled;
  final T? error;

  MaterialStatePropertyOf({
    required this.primary,
    this.hovered,
    this.focused,
    this.pressed,
    this.dragged,
    this.selected,
    this.scrolledUnder,
    this.disabled,
    this.error
  });

  @override
  T resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return hovered ?? primary;
    }
    if (states.contains(MaterialState.focused)) {
      return focused ?? primary;
    }
    if (states.contains(MaterialState.pressed)) {
      return pressed ?? primary;
    }
    if (states.contains(MaterialState.dragged)) {
      return dragged ?? primary;
    }
    if (states.contains(MaterialState.selected)) {
      return selected ?? primary;
    }
    if (states.contains(MaterialState.scrolledUnder)) {
      return scrolledUnder ?? primary;
    }
    if (states.contains(MaterialState.disabled)) {
      return disabled ?? primary;
    }
    if (states.contains(MaterialState.error)) {
      return error ?? primary;
    }
    return primary;
  }
}