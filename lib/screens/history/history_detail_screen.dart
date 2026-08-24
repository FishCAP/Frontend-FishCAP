import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../services/api_service.dart';
import '../../utils/page_transitions.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../schedule/schedule_screen.dart';
import 'history_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _detailFuture = _api.getPondById(widget.pondId);
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    widget.pondName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
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
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                color: Colors.white,
                size: 24,
              ),
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: Icon(
              Icons.person,
              color: AppTheme.textSecondary,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(Map<String, dynamic> pond) {
    // Extract fields with fallbacks
    final fishCount = pond['fishCount']?.toString() ?? 'N/A';
    final fishType = pond['fishType']?.toString() ?? 'Unknown';
    final stockingDuration = pond['stockingDuration']?.toString() ?? 'N/A';
    final expectedHarvest = pond['expectedHarvest']?.toString() ?? 'N/A';

    // Alert
    final alertTitle = pond['alertTitle']?.toString() ?? '';
    final alertMessage = pond['alertMessage']?.toString() ?? '';
    final hasAlert = alertTitle.isNotEmpty;

    // Water quality
    final oxygen = pond['oxygen']?.toString() ?? '0';
    final oxygenUnit = pond['oxygenUnit']?.toString() ?? 'mg/L';
    final oxygenStatus = pond['oxygenStatus']?.toString() ?? 'Unknown';
    final temperature = pond['temperature']?.toString() ?? '0';
    final temperatureStatus =
        pond['temperatureStatus']?.toString() ?? 'Unknown';
    final pH = pond['pH']?.toString() ?? '0';
    final pHStatus = pond['pHStatus']?.toString() ?? 'Unknown';

    // Feed schedules (list)
    final feedSchedules = pond['feedSchedules'] as List<dynamic>? ?? [];

    // Monitoring image (optional)
    final monitoringImage = pond['monitoringImage']?.toString() ?? '';

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
                  title: 'Fish Count',
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

          // Water Quality Status Section
          Text(
            'Water Quality Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 16),

          // Water Quality Cards
          Row(
            children: [
              Expanded(
                child: _buildWaterQualityCard(
                  context,
                  title: 'Oxygen (O2)',
                  value: oxygen,
                  unit: oxygenUnit,
                  status: oxygenStatus,
                  statusColor: oxygenStatus == 'Optimal'
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWaterQualityCard(
                  context,
                  title: 'Temp',
                  value: temperature,
                  status: temperatureStatus,
                  statusColor: temperatureStatus == 'Optimal'
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // pH Level Card
          Row(
            children: [
              Expanded(
                child: _buildWaterQualityCard(
                  context,
                  title: 'pH Level',
                  value: pH,
                  status: pHStatus,
                  statusColor: pHStatus == 'Optimal'
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
                        'Tank #01',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Active Monitoring',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feed Schedule Cards (dynamic)
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
                  ? Icons.cached
                  : Icons.access_time;
              final scheduleId = schedule['id']?.toString() ?? '';

              return Column(
                children: [
                  _buildFeedScheduleCard(
                    context,
                    time: time,
                    title: title,
                    status: status,
                    statusColor: statusColor,
                    icon: icon,
                    onEdit: () => _editFeedSchedule(
                        context, scheduleId, time, title),
                    onDelete: () => _deleteFeedSchedule(context, scheduleId, time),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          const SizedBox(height: 20),
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
            Icon(
              icon,
              size: 24,
              color: AppTheme.textSecondary,
            ),
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

  Widget _buildWaterQualityCard(
    BuildContext context, {
    required String title,
    required String value,
    String? unit,
    required String status,
    required Color statusColor,
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
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 28,
                    ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: statusColor,
              ),
              const SizedBox(width: 4),
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

  Widget _buildFeedScheduleCard(
    BuildContext context, {
    required String time,
    required String title,
    required String status,
    required Color statusColor,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outlined,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Edit feed schedule
  void _editFeedSchedule(
      BuildContext context, String scheduleId, String time, String title) {
    final newTimeController = TextEditingController(text: time);
    final newTitleController = TextEditingController(text: title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Feed Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newTimeController,
              decoration: const InputDecoration(
                labelText: 'Time',
                hintText: 'e.g., 8:00 AM',
              ),
            ),
            TextField(
              controller: newTitleController,
              decoration: const InputDecoration(
                labelText: 'Feed Type',
                hintText: 'e.g., Morning Feed',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (newTimeController.text.isNotEmpty &&
                  newTitleController.text.isNotEmpty) {
                Navigator.pop(context);
                // TODO: Call API to update schedule
                // final result = await _api.updateFeedSchedule(scheduleId, ...);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Schedule updated: ${newTimeController.text} - ${newTitleController.text}'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
                // Refresh detail after update
                setState(() {
                  _detailFuture = _api.getPondById(widget.pondId);
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Delete feed schedule
  void _deleteFeedSchedule(
      BuildContext context, String scheduleId, String time) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feed Schedule'),
        content: Text('Are you sure you want to delete the schedule for $time?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Call API to delete schedule
              // final result = await _api.deleteFeedSchedule(scheduleId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Schedule for $time deleted'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
              // Refresh detail after deletion
              setState(() {
                _detailFuture = _api.getPondById(widget.pondId);
              });
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}