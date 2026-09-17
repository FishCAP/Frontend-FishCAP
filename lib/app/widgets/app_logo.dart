import 'package:flutter/material.dart';
import '../theme.dart';

/// A reusable widget that displays the FishCAP logo from `assets/logo.png`.
///
/// Falls back to a stylized water-drop icon if the asset cannot be loaded,
/// so the UI never breaks when the image is missing.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(size / 5),
          ),
          child: Icon(
            Icons.water_drop,
            size: size / 2,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
