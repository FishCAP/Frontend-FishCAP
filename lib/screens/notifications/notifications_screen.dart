import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.notificationsTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.notificationsTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(l10n.markAllRead),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notification Items
              _buildNotificationItem(
                context,
                'Water Quality Alert',
                'pH level is below normal range in Pond A',
                '2 minutes ago',
                Icons.warning_amber,
                AppTheme.warningColor,
                true,
              ),

              const SizedBox(height: 12),

              _buildNotificationItem(
                context,
                'Feeding Reminder',
                'Time to feed fish in Pond A',
                '30 minutes ago',
                Icons.restaurant,
                AppTheme.primaryColor,
                true,
              ),

              const SizedBox(height: 12),

              _buildNotificationItem(
                context,
                'Task Completed',
                'Water change completed in Pond B',
                '1 hour ago',
                Icons.check_circle,
                AppTheme.successColor,
                false,
              ),

              const SizedBox(height: 12),

              _buildNotificationItem(
                context,
                'Health Alert',
                'Unusual behavior detected in Pond C',
                '2 hours ago',
                Icons.health_and_safety,
                AppTheme.errorColor,
                true,
              ),

              const SizedBox(height: 12),

              _buildNotificationItem(
                context,
                'Schedule Update',
                'Health check rescheduled to 3:00 PM',
                '3 hours ago',
                Icons.schedule,
                AppTheme.secondaryColor,
                false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String message,
    String time,
    IconData icon,
    Color color,
    bool isUnread,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? color.withOpacity(0.05) : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isUnread
            ? Border.all(color: color.withOpacity(0.3), width: 1)
            : null,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}