import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.settingsTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),

              const SizedBox(height: 24),

              // Language Setting
              _buildSettingsItem(
                context,
                l10n.language,
                Icons.language,
                AppTheme.primaryColor,
                'English',
                () {
                  _showLanguageDialog(context);
                },
              ),

              const SizedBox(height: 12),

              // Dark Mode
              _buildSettingsItem(
                context,
                l10n.darkMode,
                Icons.dark_mode,
                AppTheme.secondaryColor,
                'Off',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dark mode coming soon!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Notifications
              _buildSettingsItem(
                context,
                l10n.notificationsSettings,
                Icons.notifications,
                AppTheme.accentColor,
                'On',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings coming soon!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Privacy
              _buildSettingsItem(
                context,
                l10n.privacy,
                Icons.privacy_tip,
                AppTheme.successColor,
                '',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy settings coming soon!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // About
              _buildSettingsItem(
                context,
                l10n.about,
                Icons.info,
                AppTheme.textSecondary,
                'v1.0.0',
                () {
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
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
            if (value.isNotEmpty)
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
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
            ListTile(
              title: const Text('English'),
              trailing: Radio<String>(
                value: 'en',
                groupValue: currentLang,
                onChanged: (value) {
                  languageProvider.changeLanguage('en');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.success),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              ),
            ),
            ListTile(
              title: const Text('ភាសាខ្មែរ'),
              trailing: Radio<String>(
                value: 'km',
                groupValue: currentLang,
                onChanged: (value) {
                  languageProvider.changeLanguage('km');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.success),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              ),
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
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.water_drop,
          color: Colors.white,
        ),
      ),
      children: [
        const Text('Precision Aquaculture Management'),
        const SizedBox(height: 8),
        Text('${l10n.version}: 1.0.0'),
      ],
    );
  }
}