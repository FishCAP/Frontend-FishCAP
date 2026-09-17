import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/page_transitions.dart';
import '../profile/profile_screen.dart';
import '../schedule/schedule_screen.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String pondId;
  final String pondName;

  const HistoryDetailScreen({
    super.key,
    required this.pondId,
    required this.pondName,
  });

  @override
  _HistoryDetailScreenState createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final ApiService _api = ApiService.instance;
  late Future<Map<String, dynamic>> _detailFuture;
  late Future<Map<String, dynamic>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _api.getPondById(widget.pondId);
    _logsFuture = _api.getFeedingLogs(pondId: widget.pondId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.pondName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

            // Main Content
            // Main Content
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _detailFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData ||
                      snapshot.data!['success'] != true) {
                    return Center(
                      child: Text(
                        snapshot.data?['message'] ?? 'Failed to load details',
                      ),
                    );
                  } else {
                    final data = snapshot.data!['data'];
                    if (data is! Map<String, dynamic>) {
                      return const Center(child: Text('Invalid data format'));
                    }
                    return _buildDetailContent(data);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // History tab is active
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                PageTransitions.fade(const ScheduleScreen()),
              );
              break;
            case 1:
              // Already on history
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                PageTransitions.fade(const ProfileScreen()),
              );
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(
              Icons.calendar_today,
              color: AppTheme.textSecondary,
            ),
            label: l10n.schedule,
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history, color: Colors.white, size: 24),
            ),
            label: l10n.history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person, color: AppTheme.textSecondary),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(Map<String, dynamic> pond) {
    final l10n = AppLocalizations.of(context)!;
    // Extract fields with fallbacks
    final fishCount = pond['fishCount']?.toString() ?? 'N/A';
    final fishType = pond['fishType']?.toString() ?? 'Unknown';
    final stockingDuration = pond['stockingDuration']?.toString() ?? 'N/A';
    final expectedHarvest = pond['expectedHarvest']?.toString() ?? 'N/A';

    // Alert
    final alertTitle = pond['alertTitle']?.toString() ?? '';
    final alertMessage = pond['alertMessage']?.toString() ?? '';
    final hasAlert = alertTitle.isNotEmpty;

    // Monitoring image (optional)
    final monitoringImage = pond['monitoringImage']?.toString() ?? '';

    // Feed schedules (list of scheduled feed times for this pond)
    final feedSchedules = pond['feedSchedules'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Cards Row 1
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: l10n.fishCount,
                  value: fishCount,
                  icon: Icons.people_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'Fish Type',
                  value: fishType,
                  icon: Icons.circle_outlined,
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
                  title: 'Stocking Duration',
                  value: stockingDuration,
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'Expected Harvest',
                  value: expectedHarvest,
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Alert Card (if any)
          if (hasAlert) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
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
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      color: AppTheme.errorColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alertTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          alertMessage,
                          style: TextStyle(
                            fontSize: 13,
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

          // Info Cards Row 3 (Total Feed, Total Fish)
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: 'Total Feed',
                  value: _calculateTotalFeed(pond),
                  icon: Icons.set_meal_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  title: l10n.fishCount,
                  value: fishCount,
                  icon: Icons.people_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Monitoring Banner
          if (monitoringImage.isNotEmpty)
            Container(
              height: 180,
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
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        l10n.tankNumber,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.activeMonitoring,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 32),

          // Feed Schedule Section - All history schedules put to the pond
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.feedSchedule,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scheduled feed times for this pond
          if (feedSchedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No scheduled feed times',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ...feedSchedules.map((schedule) {
              final time = schedule['feed_time']?.toString() ??
                  schedule['feedTime']?.toString() ??
                  schedule['time']?.toString() ??
                  '';
              final amount = schedule['feed_amount']?.toString() ??
                  schedule['feedAmount']?.toString() ??
                  schedule['amount']?.toString() ??
                  '';
              final title = schedule['title']?.toString() ?? '';
              final isActive = schedule['is_active'] ?? schedule['isActive'] ?? true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      time.isNotEmpty ? time : 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                    if (amount.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Text(
                        '$amount kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    if (title.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($title)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 16),

          // All feeding history schedules (one entry per day, summarized)
          FutureBuilder<Map<String, dynamic>>(
            future: _logsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!['success'] != true) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No feed schedules')),
                );
              }
              final dataObj = snapshot.data!['data'];
              if (dataObj == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No feed schedules')),
                );
              }

              // Group entries by date and summarize: one entry per day
              final List<Map<String, dynamic>> dailySummaries = [];
              if (dataObj is Map) {
                final Map<String, dynamic> byDate = Map<String, dynamic>.from(dataObj);
                final dateKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
                for (final dateKey in dateKeys) {
                  final items = (byDate[dateKey] as List<dynamic>?) ?? [];
                  double dayTotal = 0.0;
                  DateTime? firstDt;
                  // Try to parse the dateKey as a date (format: YYYY-MM-DD)
                  try {
                    firstDt = DateTime.parse(dateKey);
                  } catch (_) {
                    firstDt = null;
                  }
                  for (final it in items) {
                    if (it is Map<String, dynamic>) {
                      final amt = it['feed_amount'] != null
                          ? (double.tryParse(it['feed_amount'].toString()) ?? 0.0)
                          : (it['amount'] != null
                              ? (double.tryParse(it['amount'].toString()) ?? 0.0)
                              : 0.0);
                      dayTotal += amt;
                      // Try to get the first feeding time from fedAt
                      final fedRaw = it['fedAt']?.toString() ?? it['fed_at']?.toString() ?? '';
                      try {
                        final dt = fedRaw.isNotEmpty ? DateTime.parse(fedRaw) : null;
                        if (dt != null) {
                          if (firstDt != null) {
                            // Keep the date from dateKey but update the time
                            firstDt = DateTime(firstDt.year, firstDt.month, firstDt.day, dt.hour, dt.minute);
                          } else {
                            firstDt = dt;
                          }
                        }
                      } catch (_) {}
                    }
                  }
                  dailySummaries.add({
                    'dateKey': dateKey,
                    'totalAmount': dayTotal,
                    'firstTime': firstDt,
                  });
                }
              } else if (dataObj is List) {
                // Group list items by date
                final Map<String, List<Map<String, dynamic>>> grouped = {};
                for (final it in dataObj) {
                  if (it is Map<String, dynamic>) {
                    DateTime? dt;
                    final fedRaw = it['fedAt']?.toString() ?? it['fed_at']?.toString() ?? '';
                    try {
                      dt = fedRaw.isNotEmpty ? DateTime.parse(fedRaw) : null;
                    } catch (_) {}
                    final dtStr = dt != null
                        ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
                        : 'unknown';
                    grouped.putIfAbsent(dtStr, () => []).add(it);
                  }
                }
                final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
                for (final dateKey in dateKeys) {
                  final items = grouped[dateKey] ?? [];
                  double dayTotal = 0.0;
                  DateTime? firstDt;
                  for (final it in items) {
                    // CHANGED (Issue 3): accept feedAmount / feed_amount / amount.
                    final dynamic rawAmt = it['feedAmount'] ?? it['feed_amount'] ?? it['amount'];
                    final amt = rawAmt != null
                        ? (double.tryParse(rawAmt.toString()) ?? 0.0)
                        : 0.0;
                    dayTotal += amt;
                    final fedRaw = it['fedAt']?.toString() ?? it['fed_at']?.toString() ?? '';
                    try {
                      final dt = fedRaw.isNotEmpty ? DateTime.parse(fedRaw) : null;
                      if (dt != null && (firstDt == null || dt.isBefore(firstDt))) {
                        firstDt = dt;
                      }
                    } catch (_) {}
                  }
                  dailySummaries.add({
                    'dateKey': dateKey,
                    'totalAmount': dayTotal,
                    'firstTime': firstDt,
                  });
                }
              }

              if (dailySummaries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No feed schedules')),
                );
              }

              return Column(
                children: dailySummaries.map((summary) {
                  final dt = summary['firstTime'] as DateTime?;
                  final totalAmount = summary['totalAmount'] as double;
                  final dateStr = dt != null
                      ? '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year.toString().substring(2)}'
                      : 'N/A';
                  final timeStr = dt != null
                      ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                      : 'N/A';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildFeedHistoryCard(
                      context,
                      date: dateStr,
                      amount: totalAmount,
                      time: timeStr,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // Feeding history (grouped by day)
          FutureBuilder<Map<String, dynamic>>(
            future: _logsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!['success'] != true) {
                return const SizedBox.shrink();
              }
              final dataObj = snapshot.data!['data'];
              if (dataObj == null) return const SizedBox.shrink();

              // If server returned grouped map, render directly. Otherwise fall back
              // to client-side grouping for legacy endpoints.
              if (dataObj is Map) {
                final Map<String, dynamic> byDate = Map<String, dynamic>.from(dataObj);
                if (byDate.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: Text('No feeding history')),
                  );
                }
                final dateKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text('Feeding History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    ...dateKeys.map((dateKey) {
                      final items = (byDate[dateKey] as List<dynamic>?) ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateKey, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          ...items.map((it) {
                            DateTime? dt;
                            final fedRaw = it['fedAt']?.toString() ?? it['fed_at']?.toString() ?? '';
                            try {
                              dt = fedRaw.isNotEmpty ? DateTime.parse(fedRaw) : null;
                            } catch (_) {
                              dt = null;
                            }
                            final timeStr = dt != null ? DateFormat('h:mm a').format(dt) : '-';
                            final amountVal = it['feedAmount'] != null ? (double.tryParse(it['feedAmount'].toString()) ?? 0.0) : (it['feed_amount'] != null ? (double.tryParse(it['feed_amount'].toString()) ?? 0.0) : 0.0);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(timeStr, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                  Text('${amountVal.toStringAsFixed(2)} kg', style: TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                  ],
                );
              }

              // Legacy: data is a list — group client-side
              final logs = dataObj as List<dynamic>;
              if (logs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text('No feeding history')),
                );
              }
              final Map<String, List<dynamic>> byDate = {};
              for (final l in logs) {
                final fedAtStr = l['fedAt']?.toString() ?? l['fed_at']?.toString() ?? '';
                DateTime? dt;
                try {
                  dt = DateTime.parse(fedAtStr);
                } catch (_) {
                  dt = null;
                }
                final key = dt != null ? DateFormat('dd-MM-yyyy').format(dt) : 'Unknown';
                byDate.putIfAbsent(key, () => []).add({'dt': dt, 'amount': l['feedAmount'] ?? l['feed_amount']});
              }
              final dateKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text('Feeding History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  ...dateKeys.map((dateKey) {
                    final items = byDate[dateKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateKey, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        ...items.map((it) {
                          final dt = it['dt'] as DateTime?;
                          final timeStr = dt != null ? DateFormat('h:mm a').format(dt) : '-';
                          final amountVal = it['amount'] != null ? (double.tryParse(it['amount'].toString()) ?? 0.0) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(timeStr, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                                Text('${amountVal.toStringAsFixed(2)} kg', style: TextStyle(color: AppTheme.textSecondary)),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    IconData? icon,
  }) {
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
          if (icon != null) ...[
            Icon(icon, size: 24, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Calculates the total feed amount from all feeding logs for a pond.
  String _calculateTotalFeed(Map<String, dynamic> pond) {
    double total = 0.0;
    // Sum from feed_schedules if available
    final schedules = pond['feedSchedules'];
    if (schedules is List) {
      for (final s in schedules) {
        if (s is Map<String, dynamic>) {
          final amt = s['feed_amount'] ?? s['amount'] ?? s['feedAmount'];
          if (amt != null) {
            total += double.tryParse(amt.toString()) ?? 0.0;
          }
        }
      }
    }
    // Also sum from feeding_logs if present in pond data
    final logs = pond['feeding_logs'] ?? pond['feedingLogs'];
    if (logs is List) {
      for (final l in logs) {
        if (l is Map<String, dynamic>) {
          final amt = l['feed_amount'] ?? l['amount'] ?? l['feedAmount'];
          if (amt != null) {
            total += double.tryParse(amt.toString()) ?? 0.0;
          }
        }
      }
    }
    if (total == 0.0) return '0 kg';
    if (total == total.roundToDouble()) {
      return '${total.round()} kg';
    }
    return '${total.toStringAsFixed(1)} kg';
  }

  /// Builds a card showing a single feeding history entry:
  /// day:DD-MM-YY, amount: Xkg, time: HH:MM
  Widget _buildFeedHistoryCard(
    BuildContext context, {
    required String date,
    required double amount,
    required String time,
  }) {
    final amountStr = amount == amount.roundToDouble()
        ? '${amount.round()} kg'
        : '${amount.toStringAsFixed(1)} kg';
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
            child: Icon(Icons.set_meal, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'day: $date',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'amount: $amountStr',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            'time: $time',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

}
