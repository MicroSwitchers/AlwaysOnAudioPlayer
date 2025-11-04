import 'package:flutter/material.dart';

/// Layout configuration helpers so we can keep the UI readable on
/// the Raspberry Pi's 5" touchscreen while still scaling on desktops.
class LayoutConfig {
  const LayoutConfig._();

  /// Treat screens with a shortest side under 650 logical pixels as compact.
  static bool isCompact(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide < 650;
  }

  static double horizontalPadding(BuildContext context) {
    return isCompact(context) ? 12 : 24;
  }

  static double verticalPadding(BuildContext context) {
    return isCompact(context) ? 8 : 16;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: verticalPadding(context),
    );
  }

  static double navigationBarHeight(BuildContext context) {
    return isCompact(context) ? 60 : 80;
  }

  static double mediaTileLeadingSize(BuildContext context) {
    return isCompact(context) ? 40 : 48;
  }

  static double controlButtonDiameter(BuildContext context) {
    return isCompact(context) ? 60 : 72;
  }
}
