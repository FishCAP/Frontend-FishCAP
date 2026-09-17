import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../services/api_service.dart';
import '../../services/notification_badge.dart';
import '../../services/realtime_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService.instance;
  late Future<List<NotificationItem>> _notificationsFuture;
  StreamSubscription<Map<String, dynamic>>? _alertSub;
  final List<NotificationItem> _liveNotifications = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationsFuture = _fetchNotifications();

    _alertSub = RealtimeService.instance.notificationStream.listen((payload) {
      if (!mounted) return;

      final title = payload['title']?.toString() ?? 'Notification';
      final message = payload['message']?.toString();

      // Dedupe against existing live entries.
      final alreadyPresent = _liveNotifications.any(
        (n) => n.title == title && n.message == message,
      );
      if (alreadyPresent) return;

      final item = NotificationItem(
        id: 'live-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );

      setState(() {
        _liveNotifications.insert(0, item);
      });

      // Give the backend a beat to persist the row, then refetch — the
      // fetch will drop the live duplicate automatically.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _notificationsFuture = _fetchNotifications();
        });
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _notificationsFuture = _fetchNotifications();
      });
    }
  }

  Future<List<NotificationItem>> _fetchNotifications() async {
    final result = await _apiService.getNotifications();
    if (result['success'] == true && result['data'] is List) {
      final List data = result['data'] as List;
      final items = data
          .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Drop live entries that now have a persisted counterpart.
      _liveNotifications.removeWhere(
        (live) => items.any(
          (p) => p.title == live.title && p.message == live.message,
        ),
      );

      unreadNotificationCount.value =
          items.where((n) => !n.isRead).length +
              _liveNotifications.where((n) => !n.isRead).length;

      return items;
    }
    throw result['message'] ?? 'Failed to load notifications';
  }

  Future<void> _markNotificationRead(String id) async {
    if (id.startsWith('live-')) {
      setState(() {
        _liveNotifications.removeWhere((n) => n.id == id);
      });
      unreadNotificationCount.value = (unreadNotificationCount.value - 1)
          .clamp(0, 9999);
      return;
    }

    final previous = unreadNotificationCount.value;
    unreadNotificationCount.value = (previous - 1).clamp(0, 9999);

    final result = await _apiService.markNotificationRead(id);
    if (!mounted) return;

    if (result['success'] != true) {
      unreadNotificationCount.value = previous;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark as read')),
      );
      return;
    }

    setState(() {
      _notificationsFuture = _fetchNotifications();
    });
  }

  Future<void> _markAllRead() async {
    final result = await _apiService.markAllNotificationsRead();
    if (!mounted) return;

    if (result['success'] == true) {
      unreadNotificationCount.value = 0;
      setState(() {
        _liveNotifications.clear();
        _notificationsFuture = _fetchNotifications();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Failed to mark all as read',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _formatTimeAgo(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';

    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  IconData _iconForType(String title) {
    final t = title.toLowerCase();
    if (t.contains('ph')) return Icons.science;
    if (t.contains('tds')) return Icons.water_drop;
    if (t.contains('temp')) return Icons.thermostat;
    if (t.contains('oxygen')) return Icons.air;
    if (t.contains('feed')) return Icons.restaurant;
    if (t.contains('stock')) return Icons.inventory_2;
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
    if (t.contains('ph') || t.contains('temperature') || t.contains('oxygen')) {
      return AppTheme.errorColor;
    }
    if (t.contains('alert') || t.contains('quality')) {
      return AppTheme.warningColor;
    }
    if (t.contains('feed') || t.contains('stock')) {
      return AppTheme.primaryColor;
    }
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
            final persisted = snapshot.data ?? [];
            final notifications = [..._liveNotifications, ...persisted];

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _notificationsFuture = _fetchNotifications();
                });
                await _notificationsFuture;
              },
              child: notifications.isEmpty
                  ? ListView(
                      // Always scrollable so pull-to-refresh works on empty.
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: _buildEmpty(l10n),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final unread = !item.isRead;
                        final color = _colorForType(item.title, unread);
                        return _buildNotificationItem(item, color, unread);
                      },
                    ),
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
                  if (item.message != null && item.message!.isNotEmpty) ...[
                    Text(
                      item.message!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
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
    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'yes';
      }
      return false;
    }

    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString(),
      isRead: parseBool(json['isRead'] ?? json['read']),
      createdAt: (json['created_at'] ?? json['createdAt'])?.toString(),
    );
  }
}