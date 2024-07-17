import 'package:flutter/material.dart';


class WidgetStatePropertyOf<T> extends WidgetStateProperty<T> {
  final T primary;
  final T? hovered;
  final T? focused;
  final T? pressed;
  final T? dragged;
  final T? selected;
  final T? scrolledUnder;
  final T? disabled;
  final T? error;

  WidgetStatePropertyOf({
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
  T resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.hovered)) {
      return hovered ?? primary;
    }
    if (states.contains(WidgetState.focused)) {
      return focused ?? primary;
    }
    if (states.contains(WidgetState.pressed)) {
      return pressed ?? primary;
    }
    if (states.contains(WidgetState.dragged)) {
      return dragged ?? primary;
    }
    if (states.contains(WidgetState.selected)) {
      return selected ?? primary;
    }
    if (states.contains(WidgetState.scrolledUnder)) {
      return scrolledUnder ?? primary;
    }
    if (states.contains(WidgetState.disabled)) {
      return disabled ?? primary;
    }
    if (states.contains(WidgetState.error)) {
      return error ?? primary;
    }
    return primary;
  }
}