import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),

            SettingsItem(
              title: l10n.language,
              icon: Icons.language,
              color: AppTheme.primaryColor,
              value: 'English',
              onTap: () => _showLanguageDialog(context),
            ),

            // Dark mode toggle wired to ThemeProvider
            Consumer<ThemeProvider>(builder: (context, tp, child) {
              return SettingsItem(
                title: l10n.darkMode,
                icon: Icons.dark_mode,
                color: AppTheme.secondaryColor,
                value: tp.isDark ? 'On' : 'Off',
                onTap: () => tp.toggle(!tp.isDark),
              );
            }),

            SettingsItem(
              title: l10n.notificationsSettings,
              icon: Icons.notifications,
              color: AppTheme.accentColor,
              value: 'On',
              onTap: () => _showSnackBar(context, 'Notification settings coming soon!'),
            ),

            SettingsItem(
              title: l10n.privacy,
              icon: Icons.privacy_tip,
              color: AppTheme.successColor,
              onTap: () => _showSnackBar(context, 'Privacy settings coming soon!'),
            ),

            SettingsItem(
              title: l10n.about,
              icon: Icons.info,
              color: AppTheme.textSecondary,
              value: 'v$appVersion',
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLang = languageProvider.currentLocale.languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLang,
              onChanged: (value) {
                languageProvider.changeLanguage(value!);
                Navigator.pop(context);
                _showSnackBar(context, l10n.success);
              },
            ),
            RadioListTile<String>(
              title: const Text('ភាសាខ្មែរ'),
              value: 'km',
              groupValue: currentLang,
              onChanged: (value) {
                languageProvider.changeLanguage(value!);
                Navigator.pop(context);
                _showSnackBar(context, l10n.success);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: 'AquaControl',
      applicationVersion: appVersion,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.water_drop, color: Colors.white),
      ),
      children: [
        const Text('Precision Aquaculture Management'),
        const SizedBox(height: 8),
        Text('${l10n.version}: $appVersion'),
      ],
    );
  }
}

class SettingsItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? value;
  final VoidCallback onTap;

  const SettingsItem({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (value != null && value!.isNotEmpty)
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
