import 'package:flutter/material.dart';
import 'dart:io';

/// Layout configuration helpers so we can keep the UI readable on
/// the Raspberry Pi's 5" touchscreen while still scaling on desktops.
class LayoutConfig {
  const LayoutConfig._();

  /// Check if running on Raspberry Pi (Linux ARM)
  static bool get isRaspberryPi {
    return Platform.isLinux && (Platform.version.contains('arm') || Platform.version.contains('aarch'));
  }

  /// Treat screens with a shortest side under 650 logical pixels as compact.
  /// Raspberry Pi 5" screens are typically 800x480, so they'll be compact.
  static bool isCompact(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide < 650 || isRaspberryPi;
  }

  /// Extra compact mode for very small screens (5" Raspberry Pi screens)
  static bool isExtraCompact(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.shortestSide < 500;
  }

  static double horizontalPadding(BuildContext context) {
    if (isExtraCompact(context)) return 8;
    return isCompact(context) ? 12 : 24;
  }

  static double verticalPadding(BuildContext context) {
    if (isExtraCompact(context)) return 6;
    return isCompact(context) ? 8 : 16;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding(context),
      vertical: verticalPadding(context),
    );
  }

  static double navigationBarHeight(BuildContext context) {
    if (isExtraCompact(context)) return 56;
    return isCompact(context) ? 60 : 80;
  }

  static double mediaTileLeadingSize(BuildContext context) {
    if (isExtraCompact(context)) return 36;
    return isCompact(context) ? 40 : 48;
  }

  static double controlButtonDiameter(BuildContext context) {
    if (isExtraCompact(context)) return 56;
    return isCompact(context) ? 60 : 72;
  }

  /// Minimum touch target size for Raspberry Pi touchscreen
  static double get minTouchTarget => 44.0;

  /// Font scale for small screens
  static double textScaleFactor(BuildContext context) {
    if (isExtraCompact(context)) return 0.9;
    return 1.0;
  }
}
