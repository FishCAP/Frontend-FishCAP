import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../app/theme.dart';
import '../../models/pond.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import '../../utils/page_transitions.dart';
import '../schedule/schedule_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String pondId;
  final String pondName;

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

  Future<void> _loadDetail({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final result = await _api.getPondById(widget.pondId);
      if (!mounted) return;
      if (result['success'] == true && result['data'] is Map<String, dynamic>) {
        final pond = result['data'] as Map<String, dynamic>;
        setState(() {
          _pond = pond;
          _error = null;
        });

        final deviceId = (pond['sensorDeviceId'] ?? pond['deviceId'] ?? '')
            .toString();
        final lowStock = pond['lowStock'] == true || pond['lowStock'] == 'true';
        RealtimeService.instance.notifyLowStockIfNeeded(
          deviceId: deviceId,
          lowStock: lowStock,
          remainingStockGrams:
              pond['remainingStockGrams'] ?? pond['weightGrams'],
        );
      } else if (!silent || _pond == null) {
        setState(() {
          _error = result['message']?.toString() ?? 'Failed to load details';
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent || _pond == null) {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Time helpers ──────────────────────────────────────────────
  String _to24Hour(String time) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AP]M)?$',
      caseSensitive: false,
    ).firstMatch(time.trim());

    if (match == null) return time.trim();

    var hour = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    final meridiem = match.group(4)?.toUpperCase();

    if (meridiem != null) {
      if (hour < 1 || hour > 12) return time.trim();
      if (meridiem == 'PM' && hour != 12) hour += 12;
      if (meridiem == 'AM' && hour == 12) hour = 0;
    } else if (hour > 23) {
      return time.trim();
    }

    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  /// Reads schedule time from either legacy `time` or API `feedTime`.
  String _scheduleTime(Map s) => (s['time'] ?? s['feedTime'] ?? '').toString();

  /// Reads schedule amount from either legacy `amount` or API `feedAmount`.
  dynamic _scheduleAmount(Map s) =>
      s['amount'] ?? s['feedAmount'] ?? s['feed_amount'];

  TimeOfDay _parseScheduleTime(String time) {
    final parts = _to24Hour(time).split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    // CHANGED (Issue 3): log the failure instead of silently falling back.
    debugPrint('[Schedule] parse failed for "$time" → using now()');
    return TimeOfDay.now();
  }

  // Read legacy response aliases, but write only FeedingScheduleItemDto fields.
  List<Map<String, dynamic>> _scheduleUpdatePayload(List<dynamic> schedules) {
    return schedules.whereType<Map>().map((s) {
      final amount = _scheduleAmount(s);
      final amountVal = amount is num ? amount.toDouble() : 0;
      return <String, dynamic>{
        'time': _to24Hour(_scheduleTime(s)),
        'amount': amountVal,
      };
    }).toList();
  }

  Future<void> _saveScheduleList(
    List<dynamic> schedules, {
    String successMessage = 'Feed schedule updated',
  }) async {
    if (!mounted) return;

    final result = await _api.updatePond(widget.pondId, {
      'feedingSchedules': _scheduleUpdatePayload(schedules),
    });

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppTheme.successColor,
        ),
      );
      await _loadDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Failed to update feed schedule',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _editFeedSchedule(
    BuildContext context,
    List<dynamic> schedules,
    int index,
  ) async {
    if (!mounted) return;

    final raw = schedules[index];
    final original = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final initialTime = _parseScheduleTime(_scheduleTime(original));
    final timeController = TextEditingController(
      text: initialTime.format(context),
    );
    final amountController = TextEditingController(
      text: _scheduleAmount(original)?.toString() ?? '',
    );
    TimeOfDay pickedTime = initialTime;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Feed Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                readOnly: true,
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Feeding Time',
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: pickedTime,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          pickedTime = picked;
                          timeController.text = picked.format(dialogContext);
                        });
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Feed Amount (kg)',
                  hintText: 'e.g., 1.5',
                  prefixIcon: const Icon(Icons.scale_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    final newAmountText = amountController.text.trim();

    if (save != true || !mounted) {
      amountController.dispose();
      timeController.dispose();
      return;
    }
    if (index < 0 || index >= schedules.length) {
      amountController.dispose();
      timeController.dispose();
      return;
    }

    final updated = Map<String, dynamic>.from(original);
    updated['time'] =
        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
    updated['amount'] = double.tryParse(newAmountText) ?? 0;
    schedules[index] = updated;

    amountController.dispose();
    timeController.dispose();

    await _saveScheduleList(schedules);
  }

  Future<void> _deleteFeedSchedule(
    BuildContext context,
    List<dynamic> schedules,
    int index,
  ) async {
    if (!mounted) return;

    final raw = schedules[index];
    final timeLabel = raw is Map ? _scheduleTime(raw) : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feed Schedule'),
        content: Text(
          'Are you sure you want to delete the $timeLabel feeding schedule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (index >= 0 && index < schedules.length) {
      schedules.removeAt(index);
    }
    await _saveScheduleList(schedules);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
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
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadDetail(),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
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
              icon: Icons.calendar_today,
              label: l10n.schedule,
              isSelected: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageTransitions.fade(const ScheduleScreen()),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.history,
              label: l10n.history,
              isSelected: false,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageTransitions.fade(const HistoryScreen()),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.person,
              label: l10n.profile,
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

  Widget _buildBody() {
    if (_isLoading && _pond == null) {
      return const SingleChildScrollView(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _pond == null) {
      return SingleChildScrollView(child: Center(child: Text(_error!)));
    }
    if (_pond != null) {
      return _buildDashboardContent(_pond!);
    }
    return const SingleChildScrollView(
      child: Center(child: Text('Failed to load details')),
    );
  }

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

  Future<void> _togglePondStatus(bool currentlyDone) async {
    // Completing MUST release the bound hardware: the device's pond binding
    // (devices.pond_id) is the only source the ESP32 schedule poll uses.
    // PATCH /ponds/:id/complete (completePond) stamps endDate and frees the
    // device; a plain status update would leave the feeder polling a finished
    // pond's schedules. Reactivating only flips the status back.
    final result = currentlyDone
        ? await _api.updatePond(widget.pondId, {'status': Pond.activeStatus})
        : await _api.completePond(widget.pondId);
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

  // ─────────────────────────────────────────────────────────────
  //  Main content
  // ─────────────────────────────────────────────────────────────
  Widget _buildDashboardContent(Map<String, dynamic> pond) {
    final fishCount = pond['fishCount']?.toString() ?? 'N/A';
    final fishType = pond['fishType']?.toString() ?? 'Unknown';
    final stockingDuration = pond['stockingDuration']?.toString() ?? 'N/A';
    final expectedHarvest = pond['expectedHarvest']?.toString() ?? 'N/A';

    final status = (pond['status'] ?? Pond.activeStatus)
        .toString()
        .toLowerCase();
    final bool isDone =
        status == Pond.doneStatus ||
        status == 'completed' ||
        status == 'finished';

    // ── Sensor values ────────────────────────────────────────────
    final tds = pond['tds']?.toString() ?? '--';
    const tdsUnit = 'ppm';
    final tdsStatus = pond['tdsStatus']?.toString() ?? 'Unknown';

    final temperature = pond['temperature']?.toString() ?? '--';
    final temperatureStatus =
        pond['temperatureStatus']?.toString() ?? 'Unknown';

    final pH = pond['pH']?.toString() ?? '--';
    final pHStatus = pond['pHStatus']?.toString() ?? 'Unknown';

    // ── Parse numeric values (guard against nulls and dead probes) ──
    double? asDouble(String s) => s == '--' ? null : double.tryParse(s);

    final double? tdsVal = asDouble(tds);
    final double? phVal = asDouble(pH);
    final double? tempVal = asDouble(temperature);

    // A reading is "usable" only when the value is present AND non-zero.
    // TDS = 0 means the probe is disconnected — not an abnormal water
    // condition. pH = 0 is likewise impossible in real water.
    final bool hasTdsReading = tdsVal != null && tdsVal > 0;
    final bool hasPhReading = phVal != null && phVal > 0;
    final bool hasTempReading = tempVal != null && tempVal != 0;

    // Status is only trusted when the reading itself is usable.
    bool isAbnormal(String statusLabel, bool hasReading) =>
        hasReading &&
        statusLabel != 'Good' &&
        statusLabel != 'Moderate' &&
        statusLabel != 'Unknown';

    final bool tdsAbnormal = isAbnormal(tdsStatus, hasTdsReading);
    final bool phAbnormal = isAbnormal(pHStatus, hasPhReading);
    final bool tempAbnormal = isAbnormal(temperatureStatus, hasTempReading);

    // ── Low-stock detection ─────────────────────────────────────
    final dynamic rawRemaining =
        pond['remainingStockGrams'] ?? pond['weightGrams'];
    final double? remainingGrams = rawRemaining is num
        ? rawRemaining.toDouble()
        : double.tryParse(rawRemaining?.toString() ?? '');

    final bool lowStock =
        pond['lowStock'] == true ||
        (remainingGrams != null && remainingGrams > 0 && remainingGrams < 100);

    // ── Build the ordered issue list (most urgent first) ────────
    final List<String> issues = [];
    final List<String> alertSensors = [];

    if (phAbnormal) {
      issues.add('pH abnormal: $pH');
      alertSensors.add('pH');
    }
    if (tempAbnormal) {
      issues.add('Temperature abnormal: $temperature°C');
      alertSensors.add('Temp');
    }
    if (tdsAbnormal) {
      issues.add('TDS abnormal: $tds $tdsUnit');
      alertSensors.add('TDS');
    }
    if (lowStock) {
      issues.add('Low feed stock — refill the hopper soon.');
      alertSensors.add('Feed');
    }

    final backendAlertTitle = pond['alertTitle']?.toString() ?? '';
    final backendAlertMessage = pond['alertMessage']?.toString() ?? '';

    final bool hasAlert = issues.isNotEmpty || backendAlertTitle.isNotEmpty;

    final String computedAlertTitle = backendAlertTitle.isNotEmpty
        ? backendAlertTitle
        : alertSensors.isEmpty
        ? 'Sensor Alert'
        : '${alertSensors.join(' & ')} Alert';

    final String computedAlertMessage = backendAlertMessage.isNotEmpty
        ? backendAlertMessage
        : issues.join('\n');

    final feedSchedules = pond['feedSchedules'] as List<dynamic>? ?? [];
    final monitoringImage = pond['monitoringImage']?.toString() ?? '';

    // ── Add-schedule dialog (kept as a nested function to keep scope) ──
    Future<void> showAddFeedScheduleDialog(
      BuildContext context,
      List<dynamic> feedSchedules,
    ) async {
      final amountController = TextEditingController();
      final timeController = TextEditingController();
      TimeOfDay? selectedTime;

      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Feed Schedule'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  readOnly: true,
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Feeding Time',
                    hintText: 'Select time',
                    prefixIcon: const Icon(Icons.access_time),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedTime = picked;
                            timeController.text = picked.format(dialogContext);
                          });
                        }
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Feed Amount (kg)',
                    hintText: 'e.g., 1.5',
                    prefixIcon: const Icon(Icons.scale_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                onPressed: () {
                  final amount = double.tryParse(amountController.text.trim());
                  if (selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a time')),
                    );
                    return;
                  }
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      );

      final time = selectedTime == null
          ? ''
          : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
      final amountText = amountController.text.trim();

      if (shouldAdd != true || !mounted) {
        amountController.dispose();
        timeController.dispose();
        return;
      }

      // The dialog field is labelled "Feed Amount (kg)", and KILOGRAMS is the
      // unit end-to-end: FeedingScheduleItemDto.amount → feed_schedules
      // .feed_amount → the ESP32's `targetKg` (compared against the load-cell
      // reading in kg). Send the value as entered — scaling it here (a *1000
      // "grams" conversion) asked the feeder for 1000x the portion.
      feedSchedules.add({
        'time': time,
        'amount': double.tryParse(amountText) ?? 0,
      });

      await _saveScheduleList(
        feedSchedules,
        successMessage: 'Feed schedule added',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusToggle(isDone),
          const SizedBox(height: 16),

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

          // ── Alert card — only rendered when attention is required ──
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                computedAlertTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                            if (issues.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${issues.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          computedAlertMessage,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
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

          // ── Water Quality section ─────────────────────────────────
          Text(
            'Water Quality Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQualityCard(
                  context,
                  'TDS (ppm)',
                  tds,
                  tdsUnit,
                  _statusColor(tdsStatus),
                  tdsStatus,
                  Icons.water_drop,
                  isAlert: tdsAbnormal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQualityCard(
                  context,
                  'Temp',
                  temperature,
                  '°C',
                  _statusColor(temperatureStatus),
                  temperatureStatus,
                  Icons.thermostat,
                  isAlert: tempAbnormal,
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
                  isAlert: phAbnormal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildFeedStockSection(pond),
          const SizedBox(height: 24),

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
                          widget.pondName.isNotEmpty
                              ? widget.pondName
                              : 'Pond',
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

          // ── Feed Schedule section ─────────────────────────────────
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
          const SizedBox(height: 12),

          Builder(
            builder: (context) {
              final dynamic estCount =
                  pond['estimatedCount'] ?? pond['fishCount'] ?? 0;
              final int count = estCount is num
                  ? estCount.toInt()
                  : int.tryParse(estCount?.toString() ?? '0') ?? 0;
              final dynamic rawAvg =
                  pond['avgWeightGrams'] ?? pond['initialWeight'] ?? 50;
              final double avgWeight = rawAvg is num
                  ? rawAvg.toDouble()
                  : double.tryParse(rawAvg?.toString() ?? '50') ?? 50.0;
              final dynamic rawRate = pond['feedingRatePercent'] ?? 3;
              final double feedingRate = rawRate is num
                  ? rawRate.toDouble()
                  : double.tryParse(rawRate?.toString() ?? '3') ?? 3.0;
              final total = (count * avgWeight * (feedingRate / 100));
              return Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recommended daily feed',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$count fish • ${avgWeight.toStringAsFixed(0)} g/fish • ${feedingRate.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(total / 1000).toStringAsFixed(2)} kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '3x: ${(total / 3 / 1000).toStringAsFixed(3)} kg',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          if (feedSchedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No feed schedules')),
            )
          else
            ...feedSchedules.asMap().entries.map((entry) {
              final index = entry.key;
              final schedule = entry.value as Map;
              final time = _scheduleTime(schedule);
              final amount = _scheduleAmount(schedule);
              final title = (schedule['title'] ?? '').toString();
              final statusLabel = (schedule['status'] ?? 'Scheduled')
                  .toString();
              final statusColor = statusLabel == 'Scheduled'
                  ? AppTheme.primaryColor
                  : AppTheme.successColor;
              final icon = statusLabel == 'Scheduled'
                  ? Icons.schedule
                  : Icons.access_time;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFeedScheduleItem(
                  context,
                  time: time,
                  amount: amount,
                  label: title,
                  status: statusLabel,
                  statusColor: statusColor,
                  icon: icon,
                  onEdit: () =>
                      _editFeedSchedule(context, feedSchedules, index),
                  onDelete: () =>
                      _deleteFeedSchedule(context, feedSchedules, index),
                ),
              );
            }),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  showAddFeedScheduleDialog(context, feedSchedules),
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────

  String _formatWeight(dynamic grams) {
    if (grams == null) return '--';
    final double? value = grams is num
        ? grams.toDouble()
        : double.tryParse(grams.toString());
    if (value == null) return '--';
    return '${(value / 1000).toStringAsFixed(3)} kg';
  }

  Widget _buildFeedStockSection(Map<String, dynamic> pond) {
    final l10n = AppLocalizations.of(context)!;
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
        ago = l10n.justNow;
      } else if (diff.inMinutes < 60) {
        ago = '${diff.inMinutes} min ago';
      } else {
        ago = '${diff.inHours} h ago';
      }
      ageText = 'Updated $ago · ${DateFormat('HH:mm').format(updatedAt)}';
    }
    final bool isLive =
        updatedAt != null && DateTime.now().difference(updatedAt).inMinutes < 3;

    final String statusLabel;
    final Color statusColor;
    if (!hasStockData(rawWeight)) {
      statusLabel = l10n.noDataYet;
      statusColor = AppTheme.textSecondary;
    } else if (lowStock) {
      statusLabel = l10n.lowStock;
      statusColor = AppTheme.errorColor;
    } else {
      statusLabel = l10n.stockOk;
      statusColor = AppTheme.successColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.feedStockSensor,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.live,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.30),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.scale, size: 26, color: statusColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remaining feed',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatWeight(rawWeight),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
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
                    color: AppTheme.errorColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: AppTheme.errorColor,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Low feed stock — refill the hopper soon.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (deviceId.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Device: $deviceId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool hasStockData(dynamic value) {
    if (value == null) return false;
    if (value is num) return true;
    return double.tryParse(value.toString()) != null;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Good':
      case 'Optimal':
        return AppTheme.successColor;
      case 'Moderate':
        return const Color(0xFFF9A825);
      case 'Low':
      case 'High':
      case 'Abnormal':
        return AppTheme.errorColor;
      default:
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
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
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
    IconData icon, {
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAlert
            ? AppTheme.errorColor.withValues(alpha: 0.04)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isAlert
            ? Border.all(
                color: AppTheme.errorColor.withValues(alpha: 0.45),
                width: 1.5,
              )
            : null,
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (isAlert ? AppTheme.errorColor : AppTheme.textSecondary)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isAlert ? AppTheme.errorColor : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: isAlert ? 8 : 7,
                height: isAlert ? 8 : 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isAlert ? FontWeight.w700 : FontWeight.w600,
                    color: statusColor,
                  ),
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
    required dynamic amount,
    required String label,
    required String status,
    required Color statusColor,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final amountStr = amount == null
        ? ''
        : '${double.tryParse(amount.toString())?.toStringAsFixed(2) ?? amount} kg';

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
                  amountStr.isNotEmpty ? amountStr : label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
              const SizedBox(width: 2),
              IconButton(
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                tooltip: 'Edit schedule',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                tooltip: 'Delete schedule',
                icon: const Icon(
                  Icons.delete_outlined,
                  size: 18,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
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
