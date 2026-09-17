import 'package:flutter/foundation.dart';

/// Global unread-notification counter shared between the realtime socket
/// service (increments whenever an alert arrives) and the notifications
/// screen (recalculates it from the API on load and resets it after
/// mark-all-read). The app header bell listens to this to show a badge.
final ValueNotifier<int> unreadNotificationCount = ValueNotifier<int>(0);
