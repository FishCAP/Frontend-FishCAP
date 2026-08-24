import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../services/api_service.dart';
import '../../utils/page_transitions.dart';
import '../schedule/schedule_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String pondId;
  final String pondName; // optional, shown while loading

  const DashboardScreen({
    super.key,
    required this.pondId,
    this.pondName = '',
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
                      widget.pondName.isNotEmpty ? widget.pondName : 'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area (FutureBuilder)
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
                    return _buildDashboardContent(data);
                  }
                },
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

  // Build the main content with dynamic data
  Widget _buildDashboardContent(Map<String, dynamic> pond) {
    // Extract fields with fallbacks
    final fishCount = pond['fishCount']?.toString() ?? 'N/A';
    final fishType = pond['fishType']?.toString() ?? 'Unknown';
    final stockingDuration = pond['stockingDuration']?.toString() ?? 'N/A';
    final expectedHarvest = pond['expectedHarvest']?.toString() ?? 'N/A';
    final pondId = pond['id']?.toString() ?? widget.pondId; // fallback to widget.pondId

    // Alert
    final alertTitle = pond['alertTitle']?.toString() ?? '';
    final alertMessage = pond['alertMessage']?.toString() ?? '';
    final hasAlert = alertTitle.isNotEmpty;

    // Water quality
    final oxygen = pond['oxygen']?.toString() ?? '0';
    final oxygenUnit = pond['oxygenUnit']?.toString() ?? 'mg/L';
    final oxygenStatus = pond['oxygenStatus']?.toString() ?? 'Unknown';
    final temperature = pond['temperature']?.toString() ?? '0';
    final temperatureStatus = pond['temperatureStatus']?.toString() ?? 'Unknown';
    final pH = pond['pH']?.toString() ?? '0';
    final pHStatus = pond['pHStatus']?.toString() ?? 'Unknown';

    // Feed schedules
    final feedSchedules = pond['feedSchedules'] as List<dynamic>? ?? [];

    // Monitoring image
    final monitoringImage = pond['monitoringImage']?.toString() ?? '';

    Future<void> _showAddFeedScheduleDialog(
      BuildContext context, String pondId) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
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
      setState(() {
        _detailFuture = _api.getPondById(widget.pondId);
      });
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
                  oxygenStatus == 'Optimal'
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
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
                  temperatureStatus == 'Optimal'
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
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
                  pHStatus == 'Optimal'
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  pHStatus,
                  Icons.science,
                ),
              ),
            ],
          ),
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
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
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
                side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
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
          Icon(
            icon,
            size: 24,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
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
          Icon(
            icon,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
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
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}