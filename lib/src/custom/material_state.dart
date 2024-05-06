import 'package:flutter/material.dart';

import '../../xwidget.dart';

abstract class XWidgetMaterialState<T> extends MaterialStateProperty<T> {
  final T primary;
  final T? hovered;
  final T? focused;
  final T? pressed;
  final T? dragged;
  final T? selected;
  final T? scrolledUnder;
  final T? disabled;
  final T? error;

  XWidgetMaterialState({
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

@InflaterDef(inflaterType: "MaterialStateOutlineBorder", inflatesOwnChildren: false)
class XWidgetMaterialStateOutlinedBorder extends XWidgetMaterialState<OutlinedBorder> {
  XWidgetMaterialStateOutlinedBorder({
    required super.primary,
    super.hovered,
    super.focused,
    super.pressed,
    super.dragged,
    super.selected,
    super.scrolledUnder,
    super.disabled,
    super.error
  });
}

@InflaterDef(inflaterType: "MaterialStateBorderSide", inflatesOwnChildren: false)
class XWidgetMaterialStateBorderSide extends XWidgetMaterialState<BorderSide> {
  XWidgetMaterialStateBorderSide({
    required super.primary,
    super.hovered,
    super.focused,
    super.pressed,
    super.dragged,
    super.selected,
    super.scrolledUnder,
    super.disabled,
    super.error
  });
}

@InflaterDef(inflaterType: "MaterialStateMouseCursor", inflatesOwnChildren: false)
class XWidgetMaterialStateMouseCursor extends XWidgetMaterialState<MouseCursor> {
  XWidgetMaterialStateMouseCursor({
    required super.primary,
    super.hovered,
    super.focused,
    super.pressed,
    super.dragged,
    super.selected,
    super.scrolledUnder,
    super.disabled,
    super.error
  });
}

@InflaterDef(inflaterType: "MaterialStateTextStyle", inflatesOwnChildren: false)
class XWidgetMaterialStateTextStyle extends XWidgetMaterialState<TextStyle> {
  XWidgetMaterialStateTextStyle({
    required super.primary,
    super.hovered,
    super.focused,
    super.pressed,
    super.dragged,
    super.selected,
    super.scrolledUnder,
    super.disabled,
    super.error
  });
}

@InflaterDef(inflaterType: "MaterialStateColor", inflatesOwnChildren: false)
class XWidgetMaterialStateColor extends XWidgetMaterialState<Color> {
  XWidgetMaterialStateColor({
    required super.primary,
    super.hovered,
    super.focused,
    super.pressed,
    super.dragged,
    super.selected,
    super.scrolledUnder,
    super.disabled,
    super.error
  });
}

@InflaterDef(inflaterType: "MaterialStateDouble", inflatesOwnChildren: false)
class XWidgetMaterialStateDouble extends XWidgetMaterialState<double> {
  XWidgetMaterialStateDouble({
    required super.primary,
    super.hovered,
    super.focused,
    super.pressed,
    super.dragged,
    super.selected,
    super.scrolledUnder,
    super.disabled,
    super.error
  });
}

@InflaterDef(inflaterType: "MaterialStateSize", inflatesOwnChildren: false)
class XWidgetMaterialStateSize extends XWidgetMaterialState<Size> {
  XWidgetMaterialStateSize({
    required super.primary,
    super.hovered,
    super.focused,
    super.pressed,
    super.dragged,
    super.selected,
    super.scrolledUnder,
    super.disabled,
    super.error
  });
}

@InflaterDef(inflaterType: "MaterialStateEdgeInsets", inflatesOwnChildren: false)
class XWidgetMaterialStateEdgeInsets extends XWidgetMaterialState<EdgeInsetsGeometry> {
  XWidgetMaterialStateEdgeInsets({
    required super.primary,
    super.hovered,
    super.focused,
    super.pressed,
    super.dragged,
    super.selected,
    super.scrolledUnder,
    super.disabled,
    super.error
  });
}