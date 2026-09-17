import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'notification_badge.dart';

class RealtimeService {
  RealtimeService._privateConstructor();
  static final RealtimeService instance = RealtimeService._privateConstructor();

  io.Socket? _socket;
  final FlutterLocalNotificationsPlugin _notif = FlutterLocalNotificationsPlugin();
  final Map<String, bool> _lastLowStockState = {};
  final Map<String, bool> _lastTempAlertState = {};
  final Map<String, bool> _lastPhAlertState = {};
  final Map<String, bool> _lastDoAlertState = {};
  final Map<String, bool> _lastTdsAlertState = {};
  // "category|deviceId" -> last shown timestamp. Suppresses duplicate alerts
  // when the backend `notification` push and the client-side `sensor_update`
  // fallback would both fire for the same reading.
  final Map<String, int> _lastShownAt = {};
  int _nextNotificationId = 1;

  final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Map<String, dynamic>> _sensorDataStream =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Live feed of alert notifications (backend pushes and client-side
  /// fallbacks). NotificationsScreen listens to refresh its list.
  Stream<Map<String, dynamic>> get notificationStream => _notificationStream.stream;

  /// Live feed of sensor data updates pushed from the backend via WebSocket.
  /// Dashboards listen to this to refresh readings immediately instead of
  /// waiting for the next 30-second poll.
  Stream<Map<String, dynamic>> get sensorDataStream => _sensorDataStream.stream;

  /// Suppress window (ms) for the same alert category from the same device.
  static const int _dedupeWindowMs = 15000;

  /// Safe water-temperature window (°C) — mirrors the backend
  /// SensorsService.TEMP_ALERT_MIN/MAX (the dashboard shows "Abnormal"
  /// outside this range).
  static const double tempAlertMin = 20.0;
  static const double tempAlertMax = 35.0;

  /// Safe pH window and dissolved-oxygen floor — mirror the backend
  /// SensorsService.PH_ALERT_MIN/MAX and DO_ALERT_MIN, which match the
  /// dashboard status buckets (pH 6–9, DO "Low" below 3 mg/L).
  static const double phAlertMin = 6.0;
  static const double phAlertMax = 9.0;
  static const double doAlertMin = 3.0;
  // Mirror backend SensorsService.TDS_ALERT_MIN/MAX
  static const double tdsAlertMin = 100.0;
  static const double tdsAlertMax = 500.0;

  Future<void> init({required String url}) async {
    try {
      final androidPlugin = _notif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (kDebugMode) print('[Realtime] notification permission granted: $granted');
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _notif.initialize(const InitializationSettings(android: android, iOS: ios));

      _socket = io.io(url, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'path': '/ws',
      });

      _socket?.on('connect', (_) {
        if (kDebugMode) print('[Realtime] connected to $url');
      });

      _socket?.on('connect_error', (error) {
        if (kDebugMode) print('[Realtime] connect_error: $error');
      });

      _socket?.on('disconnect', (_) {
        if (kDebugMode) print('[Realtime] disconnected');
      });

      _socket?.on('sensor_update', (data) {
        try {
          final Map payload = data is String ? json.decode(data) as Map : Map.from(data as Map);
          _handleSensorUpdate(payload);
        } catch (e) {
          if (kDebugMode) print('[Realtime] sensor_update parse error: $e');
        }
      });

      // Alerts persisted by the backend (registered devices with a pond
      // owner). Raise them as local push notifications immediately.
      _socket?.on('notification', (data) {
        try {
          final Map payload = data is String ? json.decode(data) as Map : Map.from(data as Map);
          _handleBackendNotification(payload);
        } catch (e) {
          if (kDebugMode) print('[Realtime] notification parse error: $e');
        }
      });
    } catch (e) {
      if (kDebugMode) print('[Realtime] init error: $e');
    }
  }

  Future<void> _showNotification(String title, String body) async {
    // Unique ids so consecutive alerts stack in the notification shade
    // instead of overwriting each other (they previously all used id 0).
    final id = _nextNotificationId++ & 0x7fffffff;
    const androidDetails = AndroidNotificationDetails('fishcap_channel', 'FishCap',
        channelDescription: 'Alerts from fishcap devices', importance: Importance.max, priority: Priority.high);
    const iosDetails = DarwinNotificationDetails();
    await _notif.show(id, title, body, const NotificationDetails(android: androidDetails, iOS: iosDetails));
  }

  /// Show an alert at most once per [_dedupeWindowMs] per (category, device)
  /// so the backend `notification` push and the client-side `sensor_update`
  /// fallback never raise the same alert twice. Also bumps the unread badge,
  /// adds a live entry to the notification stream used by NotificationsScreen,
  /// and (for client-detected alerts) persists the row on the backend so it
  /// stays on the Notifications page across app restarts.
  Future<void> _showAlertOnce({
    required String category,
    required String deviceId,
    required String title,
    required String body,
    bool persistToServer = true,
  }) async {
    final key = '$category|$deviceId';
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastShownAt[key] ?? 0;
    if (now - last < _dedupeWindowMs) return;
    _lastShownAt[key] = now;

    unreadNotificationCount.value = unreadNotificationCount.value + 1;
    _notificationStream.add({'title': title, 'message': body});
    await _showNotification(title, body);

    if (persistToServer) {
      await _persistAlertOnServer(title, body);
    }
  }

  /// Save the alert as a backend notification row for the signed-in user so
  /// the Notifications page shows it permanently — not only while the live
  /// in-memory entry exists. Skips the write when the backend already
  /// persisted an identical row (its ingest pipeline creates the same
  /// title+message for registered devices). Failures are swallowed —
  /// persistence must never break the alert path.
  Future<void> _persistAlertOnServer(String title, String message) async {
    try {
      final existing = await ApiService.instance.getNotifications();
      final data = existing['data'];
      if (existing['success'] == true && data is List) {
        final duplicate = data.any(
          (n) =>
              n is Map &&
              n['title']?.toString() == title &&
              n['message']?.toString() == message,
        );
        if (duplicate) return;
      }
      await ApiService.instance.createNotification(title: title, message: message);
    } catch (e) {
      if (kDebugMode) print('[Realtime] persist notification failed: $e');
    }
  }

  double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  bool _isLowStock({required bool? lowStock, required dynamic remainingStockGrams}) {
    if (lowStock == true) return true;
    final grams = _toDouble(remainingStockGrams, fallback: double.infinity);
    return grams.isFinite && grams < 100.0;
  }

  void notifyLowStockIfNeeded({
    required String deviceId,
    required bool? lowStock,
    required dynamic remainingStockGrams,
  }) {
    final id = deviceId.trim();
    final bool isLowStock = _isLowStock(lowStock: lowStock, remainingStockGrams: remainingStockGrams);
    final bool wasLowStock = _lastLowStockState[id] == true;

    if (isLowStock && !wasLowStock) {
      final rkg = (_toDouble(remainingStockGrams) / 1000.0).toStringAsFixed(3);
      _lastLowStockState[id] = true;
      _showAlertOnce(
        category: 'low_stock',
        deviceId: id,
        title: 'Low feed stock',
        // Matches the backend's ingest-pipeline message word for word.
        body:
            '${id.isNotEmpty ? id : 'Device'} remaining feed is $rkg kg. Refill the hopper soon.',
      );
      return;
    }

    if (!isLowStock) {
      _lastLowStockState[id] = false;
    }
  }

  /// Raise the same water-quality alerts the pond dashboard card renders
  /// ("pH & TDS & Feed Alert") as notifications. The card flags readings
  /// with the pond's own status buckets (species-specific thresholds
  /// included), which can be stricter than the fixed windows checked by
  /// [_handlePh]/[_handleTds]/[_handleTemperature] — so the dashboard drives
  /// these directly from its computed flags. The per-category state maps and
  /// the deduped show pipeline are shared with the socket-driven fallbacks
  /// so one condition never notifies twice.
  void notifyWaterQualityAlertsIfNeeded({
    required String deviceId,
    required bool phAbnormal,
    dynamic ph,
    required bool tdsAbnormal,
    dynamic tds,
    required bool tempAbnormal,
    dynamic temperature,
  }) {
    final id = deviceId.trim();
    if (id.isEmpty) return;

    // ── pH ──
    if (phAbnormal && _lastPhAlertState[id] != true) {
      _lastPhAlertState[id] = true;
      final p = _toDouble(ph, fallback: double.nan);
      final String detail;
      if (p.isNaN) {
        detail =
            '$id water pH is abnormal. Safe range: ${phAlertMin.toInt()}-${phAlertMax.toInt()}.';
      } else {
        final kind = p < phAlertMin ? 'too low' : 'too high';
        detail =
            '$id water pH is $kind (${p.toStringAsFixed(2)}). Safe range: ${phAlertMin.toInt()}-${phAlertMax.toInt()}.';
      }
      _showAlertOnce(
        category: 'ph',
        deviceId: id,
        title: 'Water pH alert',
        body: detail,
      );
    } else if (!phAbnormal) {
      _lastPhAlertState[id] = false;
    }

    // ── TDS ──
    if (tdsAbnormal && _lastTdsAlertState[id] != true) {
      _lastTdsAlertState[id] = true;
      final t = _toDouble(tds, fallback: double.nan);
      final String detail;
      if (t.isNaN) {
        detail =
            '$id water TDS is abnormal. Safe range: ${tdsAlertMin.toInt()}-${tdsAlertMax.toInt()} ppm.';
      } else {
        final kind = t < tdsAlertMin ? 'too low' : 'too high';
        detail =
            '$id water TDS is $kind (${t.toStringAsFixed(1)} ppm). Safe range: ${tdsAlertMin.toInt()}-${tdsAlertMax.toInt()} ppm.';
      }
      _showAlertOnce(
        category: 'tds',
        deviceId: id,
        title: 'Water TDS alert',
        body: detail,
      );
    } else if (!tdsAbnormal) {
      _lastTdsAlertState[id] = false;
    }

    // ── Temperature ──
    if (tempAbnormal && _lastTempAlertState[id] != true) {
      _lastTempAlertState[id] = true;
      final t = _toDouble(temperature, fallback: double.nan);
      final String detail;
      if (t.isNaN) {
        detail =
            '$id water temperature is abnormal. Safe range: ${tempAlertMin.toInt()}-${tempAlertMax.toInt()} °C.';
      } else {
        final kind = t < tempAlertMin ? 'too low' : 'too high';
        detail =
            '$id water temperature is $kind (${t.toStringAsFixed(1)} °C). Safe range: ${tempAlertMin.toInt()}-${tempAlertMax.toInt()} °C.';
      }
      _showAlertOnce(
        category: 'temperature',
        deviceId: id,
        title: 'Water temperature alert',
        body: detail,
      );
    } else if (!tempAbnormal) {
      _lastTempAlertState[id] = false;
    }
  }

  /// Push a local notification when the water temperature leaves the safe
  /// window. Physically impossible values (e.g. the DS18B20 disconnect
  /// sentinel -127, or the 85 power-on default drift) are ignored so a
  /// broken probe cannot spam alerts.
  void _handleTemperature(String deviceId, dynamic rawTemperature) {
    if (rawTemperature == null) return;
    final t = _toDouble(rawTemperature, fallback: double.nan);
    if (t.isNaN || t < -55 || t > 125) return;

    final isAlert = t < tempAlertMin || t > tempAlertMax;
    final wasAlert = _lastTempAlertState[deviceId] == true;

    if (isAlert && !wasAlert) {
      final kind = t < tempAlertMin ? 'too low' : 'too high';
      _lastTempAlertState[deviceId] = true;
      _showAlertOnce(
        category: 'temperature',
        deviceId: deviceId,
        title: 'Water temperature alert',
        // Matches the backend's ingest-pipeline message word for word.
        body:
            '$deviceId water temperature is $kind (${t.toStringAsFixed(1)} °C). '
            'Safe range: ${tempAlertMin.toInt()}-${tempAlertMax.toInt()} °C.',
      );
    } else if (!isAlert) {
      _lastTempAlertState[deviceId] = false;
    }
  }

  /// pH alerts — transition into/out of the safe window, mirroring
  /// [_handleTemperature]. Values are validated against the physically
  /// meaningful 0–14 scale so garbage readings cannot spam alerts.
  void _handlePh(String deviceId, dynamic rawPh) {
    if (rawPh == null) return;
    final p = _toDouble(rawPh, fallback: double.nan);
    if (p.isNaN || p < 0 || p > 14) return;

    final isAlert = p < phAlertMin || p > phAlertMax;
    final wasAlert = _lastPhAlertState[deviceId] == true;

    if (isAlert && !wasAlert) {
      final kind = p < phAlertMin ? 'too low' : 'too high';
      _lastPhAlertState[deviceId] = true;
      _showAlertOnce(
        category: 'ph',
        deviceId: deviceId,
        title: 'Water pH alert',
        // Matches the backend's ingest-pipeline message word for word.
        body:
            '$deviceId water pH is $kind (${p.toStringAsFixed(2)}). '
            'Safe range: ${phAlertMin.toInt()}-${phAlertMax.toInt()}.',
      );
    } else if (!isAlert) {
      _lastPhAlertState[deviceId] = false;
    }
  }

  /// Low dissolved-oxygen alerts — fish suffocate below ~3 mg/L (the
  /// dashboard shows "Low" under this floor).
  void _handleDissolvedOxygen(String deviceId, dynamic rawDo) {
    if (rawDo == null) return;
    final d = _toDouble(rawDo, fallback: double.nan);
    if (d.isNaN || d < 0 || d > 20) return;

    final isAlert = d < doAlertMin;
    final wasAlert = _lastDoAlertState[deviceId] == true;

    if (isAlert && !wasAlert) {
      _lastDoAlertState[deviceId] = true;
      _showAlertOnce(
        category: 'dissolved_oxygen',
        deviceId: deviceId,
        title: 'Dissolved oxygen alert',
        body: '$deviceId: dissolved oxygen ${d.toStringAsFixed(1)} mg/L '
            '(minimum $doAlertMin) — check aeration',
      );
    } else if (!isAlert) {
      _lastDoAlertState[deviceId] = false;
    }
  }

  /// TDS alerts — alert when TDS falls outside the backend's safe window.
  void _handleTds(String deviceId, dynamic rawTds) {
    if (rawTds == null) return;
    final t = _toDouble(rawTds, fallback: double.nan);
    if (t.isNaN || t < 0 || t > 100000) return;

    final isAlert = t < tdsAlertMin || t > tdsAlertMax;
    final wasAlert = _lastTdsAlertState[deviceId] == true;

    if (isAlert && !wasAlert) {
      final kind = t < tdsAlertMin ? 'too low' : 'too high';
      _lastTdsAlertState[deviceId] = true;
      _showAlertOnce(
        category: 'tds',
        deviceId: deviceId,
        title: 'Water TDS alert',
        body: '$deviceId water TDS is $kind (${t.toStringAsFixed(1)} ppm). Safe range: ${tdsAlertMin.toInt()}-${tdsAlertMax.toInt()} ppm.',
      );
    } else if (!isAlert) {
      _lastTdsAlertState[deviceId] = false;
    }
  }

  /// Backend-persisted alert (registered device with a pond owner) pushed
  /// over the socket. Raise it locally unless a duplicate was just shown by
  /// the client-side fallback, and sync the transition state so the fallback
  /// stays silent for this same event.
  void _handleBackendNotification(Map payload) {
    final title = (payload['title'] ?? 'Notification').toString();
    final message = (payload['message'] ?? '').toString();
    final deviceId = (payload['deviceId'] ?? '').toString();

    String category = 'other';
    final t = title.toLowerCase();
    if (t.contains('temperature')) {
      category = 'temperature';
      _lastTempAlertState[deviceId] = true;
    } else if (t.contains('ph')) {
      category = 'ph';
      _lastPhAlertState[deviceId] = true;
    } else if (t.contains('oxygen')) {
      category = 'dissolved_oxygen';
      _lastDoAlertState[deviceId] = true;
    } else if (t.contains('stock')) {
      category = 'low_stock';
      _lastLowStockState[deviceId] = true;
    } else if (t.contains('feed')) {
      category = 'feeding';
    }

    _showAlertOnce(
      category: category,
      deviceId: deviceId,
      title: title,
      body: message,
      // The backend already persisted this row before pushing it —
      // writing it again from the client would duplicate it.
      persistToServer: false,
    );
  }

  void _handleSensorUpdate(Map payload) {
    // Example payload fields: deviceId, temperature, feeding (bool),
    // feedGramsDispensed, remainingStockGrams, lowStock
    final deviceId = (payload['deviceId'] ?? 'device').toString();
    final feeding = payload['feeding'] == true;
    final lowStock = payload['lowStock'] == true || payload['lowStock'] == 'true';
    final dispensed = payload['feedGramsDispensed'];

    if (feeding) {
      final dnum = _toDouble(dispensed);
      final dkg = (dnum / 1000.0).toStringAsFixed(3);
      _showAlertOnce(
        category: 'feeding',
        deviceId: deviceId,
        title: 'Feed dispensed',
        // Matches the backend's ingest-pipeline message word for word so
        // both rows dedupe into one entry on the Notifications page.
        body: '$deviceId finished feeding and dispensed $dkg kg.',
      );
    }

    // Water-quality alerts (push notification on transition into the alert
    // range). The backend creates the same alerts for registered devices;
    // these client-side handlers are the fallback for unregistered devices,
    // and _showAlertOnce's dedupe window prevents double notifications.
    _handleTemperature(deviceId, payload['temperature']);
    _handlePh(deviceId, payload['ph']);
    _handleDissolvedOxygen(deviceId, payload['dissolvedOxygen']);
    _handleTds(deviceId, payload['tds']);

    notifyLowStockIfNeeded(
      deviceId: deviceId,
      lowStock: lowStock || _isLowStock(lowStock: lowStock, remainingStockGrams: payload['remainingStockGrams']),
      remainingStockGrams: payload['remainingStockGrams'],
    );

    // Broadcast the raw sensor payload so dashboards can refresh immediately
    // instead of waiting for the next poll cycle.
    if (!_sensorDataStream.isClosed) {
      _sensorDataStream.add(Map<String, dynamic>.from(payload));
    }
  }

  void dispose() {
    _socket?.dispose();
    _notificationStream.close();
    _sensorDataStream.close();
  }
}
