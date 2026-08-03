import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Profile Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${l10n.appName} ${l10n.historyTitle}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.textPrimary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle
                    Text(
                      'Choose a site to monitor real-time data',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          const Icon(
                            Icons.search,
                            color: AppTheme.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search by name or species...',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'ACTIVE PONDS',
                            value: '2',
                            valueColor: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'ALERTS',
                            value: '2',
                            valueColor: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Lake A Site Card
                    _buildPondHistoryCard(
                      context,
                      name: 'Lake A',
                      species: 'Tilapia • Gen-4',
                      status: 'Optimal',
                      statusColor: AppTheme.successColor,
                      hasAlert: false,
                      icons: [
                        Icon(
                          Icons.water_drop,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        Icon(
                          Icons.thermostat,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryDetailScreen(pondName: 'Lake A'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Lake B Site Card
                    _buildPondHistoryCard(
                      context,
                      name: 'Lake B',
                      species: 'Barramundi • Juvenile',
                      status: 'Low Oxygen',
                      statusColor: AppTheme.errorColor,
                      hasAlert: true,
                      icons: [
                        Icon(
                          Icons.water_damage,
                          size: 16,
                          color: AppTheme.errorColor,
                        ),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryDetailScreen(pondName: 'Lake B'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Nursery 01 Site Card
                    _buildPondHistoryCard(
                      context,
                      name: 'Nursery 01',
                      species: 'Shrimp • Post-Larvae',
                      status: 'Optimal',
                      statusColor: AppTheme.successColor,
                      hasAlert: false,
                      icons: [
                        Icon(
                          Icons.science,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryDetailScreen(pondName: 'Nursery 01'),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/schedule');
              break;
            case 1:
              // Already on history
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/profile');
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

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color valueColor,
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
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPondHistoryCard(
    BuildContext context, {
    required String name,
    required String species,
    required String status,
    required Color statusColor,
    bool hasAlert = false,
    required List<Icon> icons,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        species,
                        style: TextStyle(
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
                  child: Row(
                    children: [
                      if (hasAlert)
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: statusColor,
                        ),
                      if (hasAlert) const SizedBox(width: 4),
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final icon in icons)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: icon,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PondHistoryDetailScreen extends StatelessWidget {
  const PondHistoryDetailScreen({super.key});

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
                    'Lake A',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Cards Row 1
                    Row(
                      children: [
                        // Fish Count Card
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            title: 'Fish Count',
                            value: '500',
                            icon: Icons.people_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Fish Type Card
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            title: 'Fish Type',
                            value: 'Tilapia',
                            icon: Icons.circle_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Info Cards Row 2
                    Row(
                      children: [
                        // Stocking Duration Card
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            title: 'Stocking Duration',
                            value: 'Day 45',
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Expected Harvest Card
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            title: 'Expected Harvest',
                            value: 'Oct 24, 2026',
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Alert Card
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
                                  'Low Feed Level (0.8kg)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Feeder contains less than 1kg of feed',
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
                        // Oxygen Card
                        Expanded(
                          child: _buildWaterQualityCard(
                            context,
                            title: 'Oxygen (O2)',
                            value: '6.5',
                            unit: 'mg/L',
                            status: 'Optimal',
                            statusColor: AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Temperature Card
                        Expanded(
                          child: _buildWaterQualityCard(
                            context,
                            title: 'Temp',
                            value: '28.4°C',
                            status: 'Optimal',
                            statusColor: AppTheme.successColor,
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
                            value: '6.8',
                            status: 'Warning',
                            statusColor: AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Active Monitoring Banner
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1544552866-d3ed42536cfd?w=800'),
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

                    // Feed Schedule Cards
                    _buildFeedScheduleCard(
                      context,
                      time: '8:00 AM',
                      title: 'Morning Feed',
                      status: 'Pending',
                      statusColor: AppTheme.successColor,
                      icon: Icons.access_time,
                    ),

                    const SizedBox(height: 12),

                    _buildFeedScheduleCard(
                      context,
                      time: '4:00 PM',
                      title: 'Evening Feed',
                      status: 'Scheduled',
                      statusColor: AppTheme.primaryColor,
                      icon: Icons.cached,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on schedule
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/history');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 24,
              ),
            ),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: Icon(
              Icons.history,
              color: AppTheme.textSecondary,
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
          // Time Icon
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
          // Schedule Details
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
          // Status and Actions
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
                onPressed: () => _editFeedSchedule(context, time, title),
                icon: Icon(
                  Icons.edit_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () => _deleteFeedSchedule(context, time),
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

  void _editFeedSchedule(BuildContext context, String time, String title) {
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
            onPressed: () {
              if (newTimeController.text.isNotEmpty && newTitleController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Schedule updated: ${newTimeController.text} - ${newTitleController.text}'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteFeedSchedule(BuildContext context, String time) {
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Schedule for $time deleted'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
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