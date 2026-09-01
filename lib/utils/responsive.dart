import 'package:flutter/material.dart';

/// Centralised responsive-breakpoint helper used across screens.
///
/// Breakpoints follow the Material spec:
///   - Mobile:   width < 600
///   - Tablet:   600 ≤ width < 1024
///   - Desktop:  width ≥ 1024
class ScreenHelper {
  ScreenHelper._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Whether the device is a phone / small handset.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Whether the device is a tablet or small tablet.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  /// Whether the device is a desktop / large window.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Current device logical "form factor" as an enum.
  static ScreenType screenType(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileBreakpoint) return ScreenType.mobile;
    if (w < tabletBreakpoint) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  /// A value that scales with the screen width.
  /// [defaultValue] is returned for mobile, scaled up for wider screens.
  static double responsive(
    BuildContext context,
    double defaultValue, {
    double min = 0,
    double max = double.infinity,
  }) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / mobileBreakpoint).clamp(0.8, 1.6);
    final result = defaultValue * scale;
    return result.clamp(min, max);
  }

  /// Responsive font size: scales from mobile → desktop.
  static double fontSize(BuildContext context, double size) =>
      responsive(context, size, min: size * 0.8);

  /// Horizontal page padding that increases with screen width.
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileBreakpoint) return 20.0;
    if (w < tabletBreakpoint) return 32.0;
    return 48.0;
  }

  /// Number of columns for a stats grid.
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileBreakpoint) return 1;
    if (w < tabletBreakpoint) return 3;
    return 4;
  }

  /// Profile image diameter based on screen width.
  static double profileImageSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < mobileBreakpoint) return 100.0;
    if (w < tabletBreakpoint) return 120.0;
    return 140.0;
  }
}

enum ScreenType { mobile, tablet, desktop }
