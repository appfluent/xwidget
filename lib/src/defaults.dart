import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _kBottomSheetDominatesPercentage = 0.3;
const double _kMinBottomSheetScrimOpacity = 0.1;
const double _kMaxBottomSheetScrimOpacity = 0.6;

Widget defaultBottomSheetScrimBuilder(BuildContext context, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (BuildContext context, Widget? child) {
      final double extentRemaining = _kBottomSheetDominatesPercentage * (1.0 - animation.value);
      final double floatingButtonVisibilityValue =
          extentRemaining * _kBottomSheetDominatesPercentage * 10;

      final double opacity = math.max(
        _kMinBottomSheetScrimOpacity,
        _kMaxBottomSheetScrimOpacity - floatingButtonVisibilityValue,
      );

      return ModalBarrier(dismissible: false, color: Colors.black.withOpacity(opacity));
    },
  );
}
