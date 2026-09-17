import 'package:flutter/material.dart';
import '../theme.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;

  const AppHeader({Key? key, this.title = 'FishCAP', this.height = 72}) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        );

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: Colors.transparent,
        child: Row(
          children: [
            // Left avatar / app logo (uses assets/logo.png if available)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Title
            Expanded(
              child: Center(
                child: Text(title, style: textStyle),
              ),
            ),

            // Right notification button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.notifications_none, color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
