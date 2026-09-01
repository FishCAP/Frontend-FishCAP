import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../utils/responsive.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.help),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(ScreenHelper.horizontalPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.help,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              _buildFaqItem(
                context,
                title: l10n.createNewSchedule,
                content:
                    'Navigate to an active pond on the Schedule tab, tap "Add New Time", '
                    'set the feed time and amount, then Save.',
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                context,
                title: l10n.edit,
                content:
                    'On the Schedule or Dashboard screen, tap the edit (pencil) icon next to '
                    'a feed schedule to modify its time or amount.',
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                context,
                title: l10n.delete,
                content:
                    'On the Schedule or Dashboard screen, tap the delete (trash) icon next '
                    'to a feed schedule to remove it.',
              ),
              const SizedBox(height: 16),
              _buildFaqItem(
                context,
                title: l10n.profile,
                content:
                    'View your profile, edit personal details, check your stats, and access '
                    'Settings, Help, and Logout from the Preferences section.',
              ),
              const SizedBox(height: 24),
              Text(
                'Contact',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Icons.email_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: Text('support@aquacontrol.com'),
              ),
              ListTile(
                leading: Icon(
                  Icons.phone_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: Text('+855 12 345 678'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return ExpansionTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            content,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }
}
