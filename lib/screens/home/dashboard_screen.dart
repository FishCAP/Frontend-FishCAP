import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../app/theme.dart';
import '../../models/pond.dart';
import '../../services/api_service.dart';
import '../../utils/page_transitions.dart';
import '../schedule/schedule_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String pondId;
  final String pondName; // optional, shown while loading

  const DashboardScreen({super.key, required this.pondId, this.pondName = ''});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService.instance;
  Map<String, dynamic>? _pond;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    // The ESP32 pushes fresh sensor telemetry every ~60s; poll the pond
    // detail (which embeds the latest sensor readings) every 30s so the
    // dashboard updates automatically while the page stays open.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadDetail(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Fetches the pond detail (including the latest sensor readings).
  /// When [silent] is true the currently displayed data stays on screen
  /// while refreshing — used by the auto-poll so values change in place
  /// instead of flashing a spinner.
  Future<void> _loadDetail({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final result = await _api.getPondById(widget.pondId);
      if (!mounted) return;
      if (result['success'] == true && result['data'] is Map<String, dynamic>) {
        setState(() {
          _pond = result['data'] as Map<String, dynamic>;
          _error = null;
        });
      } else if (!silent || _pond == null) {
        setState(() {
          _error = result['message']?.toString() ?? 'Failed to load details';
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Keep stale data visible on silent background refresh failures.
      if (!silent || _pond == null) {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button (always visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  Expanded(
                    child: Text(
                      widget.pondName.isNotEmpty
                          ? widget.pondName
                          : 'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area (auto-refreshing, pull-to-refresh enabled)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadDetail(),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),

      // Custom Bottom Navigation (unchanged)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: Icons.calendar_today,
              label: 'Schedule',
              isSelected: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageTransitions.fade(const ScheduleScreen()),
                );
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.history,
              label: 'History',
              isSelected: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageTransitions.fade(const HistoryScreen()),
                );
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.person,
              label: 'Profile',
              isSelected: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageTransitions.fade(const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Resolves the main scrollable body from the cached pond data.
  Widget _buildBody() {
    if (_isLoading && _pond == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _pond == null) {
      return Center(child: Text(_error!));
    }
    if (_pond != null) {
      return _buildDashboardContent(_pond!);
    }
    return const Center(child: Text('Failed to load details'));
  }

  /// Builds the prominent Active / Done toggle displayed at the top of the
  /// pond dashboard. An active pond can be marked as done (it then moves to
  /// History); a done pond can be reactivated (it then returns to Schedule).
  Widget _buildStatusToggle(bool isDone) {
    final Color accent = isDone ? AppTheme.warningColor : AppTheme.successColor;
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _togglePondStatus(isDone),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDone ? 'Status: Completed' : 'Status: Active',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDone ? 'Reactivate' : 'Mark as Done',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toggles the pond's status between active and done, persists the change
  /// to the backend, and pops back to the Schedule screen so the active/done
  /// lists are refreshed.
  Future<void> _togglePondStatus(bool currentlyDone) async {
    final targetStatus = currentlyDone ? Pond.activeStatus : Pond.doneStatus;
    final result = await _api.updatePond(widget.pondId, {
      'status': targetStatus,
    });
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentlyDone
                ? '${widget.pondName} reactivated — back on Schedule'
                : '${widget.pondName} marked as Done — moved to History',
          ),
          backgroundColor: currentlyDone
              ? AppTheme.successColor
              : AppTheme.warningColor,
        ),
      );
      // Let the user read the confirmation, then return to the Schedule
      // screen so the active/done lists reflect the new status.
      await Future.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update status'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Build the main content with dynamic data
  Widget _buildDashboardContent(Map<String, dynamic> pond) {
    // Extract fields with fallbacks
    final fishCount = pond['fishCount']?.toString() ?? 'N/A';
    final fishType = pond['fishType']?.toString() ?? 'Unknown';
    final stockingDuration = pond['stockingDuration']?.toString() ?? 'N/A';
    final expectedHarvest = pond['expectedHarvest']?.toString() ?? 'N/A';
    final pondId =
        pond['id']?.toString() ?? widget.pondId; // fallback to widget.pondId

    // Status toggle: 'active' ponds live on the Schedule screen, 'done'
    // ponds live in the History screen. Tapping the toggle in the dashboard
    // flips a pond between the two.
    final status = (pond['status'] ?? Pond.activeStatus)
        .toString()
        .toLowerCase();
    final bool isDone =
        status == Pond.doneStatus ||
        status == 'completed' ||
        status == 'finished';

    // Alert
    final alertTitle = pond['alertTitle']?.toString() ?? '';
    final alertMessage = pond['alertMessage']?.toString() ?? '';
    final hasAlert = alertTitle.isNotEmpty;

    // Water quality. Backend sends null when no sensor data exists yet —
    // show "--" instead of a misleading 0.
    final oxygen = pond['oxygen']?.toString() ?? '--';
    final oxygenUnit = pond['oxygenUnit']?.toString() ?? 'mg/L';
    final oxygenStatus = pond['oxygenStatus']?.toString() ?? 'Unknown';
    final temperature = pond['temperature']?.toString() ?? '--';
    final temperatureStatus =
        pond['temperatureStatus']?.toString() ?? 'Unknown';
    final pH = pond['pH']?.toString() ?? '--';
    final pHStatus = pond['pHStatus']?.toString() ?? 'Unknown';

    // Feed schedules
    final feedSchedules = pond['feedSchedules'] as List<dynamic>? ?? [];

    // Monitoring image
    final monitoringImage = pond['monitoringImage']?.toString() ?? '';

    Future<void> _showAddFeedScheduleDialog(
      BuildContext context,
      String pondId,
    ) async {
      final timeController = TextEditingController();
      final titleController = TextEditingController();

      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add Feed Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'e.g., 8:00 AM',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Feed Type',
                  hintText: 'e.g., Morning Feed',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add'),
            ),
          ],
        ),
      );

      if (shouldAdd != true) return;

      final time = timeController.text.trim();
      final title = titleController.text.trim();

      if (time.isEmpty || title.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
        return;
      }

      final result = await _api.addFeedSchedule(
        pondId: pondId,
        time: time,
        title: title,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feed schedule added'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        // Refresh the detail data
        await _loadDetail();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add schedule'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active / Done toggle
          _buildStatusToggle(isDone),
          const SizedBox(height: 16),

          // Info Cards Row 1
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Fish Count',
                  fishCount,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Fish Type',
                  fishType,
                  Icons.eco,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info Cards Row 2
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Stocking Duration',
                  stockingDuration,
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  'Expected Harvest',
                  expectedHarvest,
                  Icons.event_available,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Alert Card (if any)
          if (hasAlert) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alertTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alertMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Water Quality Status Section
          Text(
            'Water Quality Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Water Quality Cards (3 cards in a row)
          Row(
            children: [
              Expanded(
                child: _buildQualityCard(
                  context,
                  'Oxygen (O2)',
                  oxygen,
                  oxygenUnit,
                  _statusColor(oxygenStatus),
                  oxygenStatus,
                  Icons.air,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQualityCard(
                  context,
                  'Temp',
                  temperature,
                  '',
                  _statusColor(temperatureStatus),
                  temperatureStatus,
                  Icons.thermostat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQualityCard(
                  context,
                  'pH Level',
                  pH,
                  '',
                  _statusColor(pHStatus),
                  pHStatus,
                  Icons.science,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Feed stock (HX711 load cell) — live sensor weight
          _buildFeedStockSection(pond),
          const SizedBox(height: 24),

          // Active Monitoring Image Card (if image URL provided)
          if (monitoringImage.isNotEmpty) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(monitoringImage),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tank #01',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const Text(
                          'Active Monitoring',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Feed Schedule Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Feed Schedule',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Today',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feed Schedule Items (dynamic)
          // Feed Schedule Items (dynamic)
          if (feedSchedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No feed schedules')),
            )
          else
            ...feedSchedules.map((schedule) {
              final time = schedule['time']?.toString() ?? '';
              final title = schedule['title']?.toString() ?? '';
              final status = schedule['status']?.toString() ?? 'Pending';
              final statusColor = status == 'Scheduled'
                  ? AppTheme.primaryColor
                  : AppTheme.successColor;
              final icon = status == 'Scheduled'
                  ? Icons.schedule
                  : Icons.access_time;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFeedScheduleItem(
                  context,
                  time: time,
                  label: title,
                  status: status,
                  statusColor: statusColor,
                  icon: icon,
                ),
              );
            }),

          const SizedBox(height: 16),
          // Add New Time Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddFeedScheduleDialog(context, pondId),
              icon: const Icon(Icons.add_alarm, color: AppTheme.primaryColor),
              label: const Text(
                'Add New Time',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Helper widgets (unchanged from original except for minor adjustments)

  /// Formats a weight given in grams; switches to kg above 1 kg. The backend
  /// serializes DECIMAL columns as strings, so accept num or String input.
  String _formatWeight(dynamic grams) {
    if (grams == null) return '--';
    final double? value =
        grams is num ? grams.toDouble() : double.tryParse(grams.toString());
    if (value == null) return '--';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)} kg';
    return '${value.toStringAsFixed(1)} g';
  }

  /// "Feed Stock (Sensor)" section — live HX711 load-cell weight of the
  /// remaining feed. Values refresh automatically via the 30s poll, and the
  /// card highlights when the ESP32 reports a low-stock condition.
  Widget _buildFeedStockSection(Map<String, dynamic> pond) {
    final dynamic rawWeight =
        pond['remainingStockGrams'] ?? pond['weightGrams'];
    final bool lowStock = pond['lowStock'] == true;
    final String deviceId = pond['sensorDeviceId']?.toString() ?? '';

    DateTime? updatedAt;
    final rawUpdated = pond['lastReadingAt']?.toString();
    if (rawUpdated != null && rawUpdated.isNotEmpty) {
      updatedAt = DateTime.tryParse(rawUpdated)?.toLocal();
    }

    final String ageText;
    if (updatedAt == null) {
      ageText = 'Waiting for sensor data…';
    } else {
      final diff = DateTime.now().difference(updatedAt);
      final String ago;
      if (diff.inSeconds < 90) {
        ago = 'just now';
      } else if (diff.inMinutes < 60) {
        ago = '${diff.inMinutes} min ago';
      } else {
        ago = '${diff.inHours} h ago';
      }
      ageText = 'Updated $ago · ${DateFormat('HH:mm').format(updatedAt)}';
    }
    final bool isLive = updatedAt != null &&
        DateTime.now().difference(updatedAt).inMinutes < 3;

    final String statusLabel;
    final Color statusColor;
    if (!hasStockData(rawWeight)) {
      statusLabel = 'No data yet';
      statusColor = AppTheme.textSecondary;
    } else if (lowStock) {
      statusLabel = 'Low stock';
      statusColor = AppTheme.errorColor;
    } else {
      statusLabel = 'Stock OK';
      statusColor = AppTheme.successColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Feed Stock (Sensor)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            if (isLive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.scale,
                      size: 28,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining feed',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatWeight(rawWeight),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (lowStock) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: AppTheme.errorColor,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Low feed stock — refill the hopper soon.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ageText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (deviceId.isNotEmpty)
                    Text(
                      'Device: $deviceId',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// True when the payload carries a usable weight value (num or numeric
  /// string — DECIMAL columns arrive as strings).
  bool hasStockData(dynamic value) {
    if (value == null) return false;
    if (value is num) return true;
    return double.tryParse(value.toString()) != null;
  }

  /// Maps a backend water-quality status label to the dot/border color.
  /// The backend sends Good/Moderate/Low/Abnormal/Unknown (never "Optimal",
  /// which is why every card previously rendered with the error color).
  Color _statusColor(String? status) {
    switch (status) {
      case 'Good':
      case 'Optimal':
        return AppTheme.successColor;
      case 'Moderate':
        return const Color(0xFFF9A825); // amber warning
      case 'Low':
      case 'High':
      case 'Abnormal':
        return AppTheme.errorColor;
      default: // 'Unknown' or anything unrecognized
        return AppTheme.textSecondary;
    }
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color statusColor,
    String status,
    IconData icon,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedScheduleItem(
    BuildContext context, {
    required String time,
    required String label,
    required String status,
    required Color statusColor,
    required IconData icon,
  }) {
    return Container(
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
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
