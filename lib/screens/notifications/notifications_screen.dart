import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<NotificationItem>> _fetchNotifications() async {
    final result = await _apiService.getNotifications();
    if (result['success'] == true && result['data'] is List) {
      final List data = result['data'] as List;
      return data
          .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw result['message'] ?? 'Failed to load notifications';
  }

  Future<void> _markNotificationRead(String id) async {
    final result = await _apiService.markNotificationRead(id);
    if (result['success'] == true) {
      setState(() {
        _notificationsFuture = _fetchNotifications();
      });
    }
  }

  Future<void> _markAllRead() async {
    final result = await _apiService.markAllNotificationsRead();
    if (result['success'] == true) {
      setState(() {
        _notificationsFuture = _fetchNotifications();
      });
    }
  }

  String _formatTimeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _iconForType(String title) {
    final t = title.toLowerCase();
    if (t.contains('feed')) return Icons.restaurant;
    if (t.contains('water') || t.contains('ph') || t.contains('quality')) {
      return Icons.water_drop;
    }
    if (t.contains('harvest') || t.contains('stocking')) {
      return Icons.inventory_2;
    }
    if (t.contains('health')) return Icons.health_and_safety;
    if (t.contains('alert')) return Icons.warning_amber;
    return Icons.notifications;
  }

  Color _colorForType(String title, bool unread) {
    if (!unread) return AppTheme.textSecondary;
    final t = title.toLowerCase();
    if (t.contains('alert') || t.contains('quality')) {
      return AppTheme.warningColor;
    }
    if (t.contains('feed')) return AppTheme.primaryColor;
    if (t.contains('health')) return AppTheme.errorColor;
    return AppTheme.successColor;
  }

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
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              l10n.markAllRead,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<NotificationItem>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Text(l10n.loading));
            }
            if (snapshot.hasError) {
              return _buildError(l10n);
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return _buildEmpty(l10n);
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                final unread = !item.isRead;
                final color = _colorForType(item.title, unread);
                return _buildNotificationItem(item, color, unread);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(l10n.error, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notificationsFuture = _fetchNotifications();
              });
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.notificationsEmpty,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationItem item,
    Color color,
    bool isUnread,
  ) {
    return InkWell(
      onTap: isUnread ? () => _markNotificationRead(item.id) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? color.withValues(alpha: 0.05) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
              : null,
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
              child: Icon(_iconForType(item.title), color: color, size: 24),
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
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  if (item.message != null && item.message!.isNotEmpty)
                    Text(
                      item.message!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (item.message != null && item.message!.isNotEmpty)
                    const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(item.createdAt),
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
      ),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String? message;
  final bool isRead;
  final String? createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    this.message,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String?,
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}
