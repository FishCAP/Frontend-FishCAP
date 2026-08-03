import 'package:flutter/material.dart';
import '../../app/theme.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String pondName;

  const HistoryDetailScreen({
    super.key,
    required this.pondName,
  });

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.textPrimary,
                      size: 28,
                    ),
                  ),

                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        '$pondName - History',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                  ),

                  // Notification Bell
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.textPrimary,
                      ),
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
                    // Stats Cards Row 1
                    Row(
                      children: [
                        // Total Feed Card
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'TOTAL FEED (WEEK)',
                            value: '420',
                            unit: 'kg',
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Avg Daily Dose Card
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'AVG DAILY DOSE',
                            value: '60',
                            unit: 'kg',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Feed Type Card
                    Container(
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
                            'FEED TYPE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'BioMar 2.0',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Stats Cards Row 2
                    Row(
                      children: [
                        // Initial Count Card
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'INITIAL COUNT',
                            value: '50,000',
                            unit: 'units',
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Stocking Period Card
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: 'STOCKING PERIOD',
                            value: 'Aug 25',
                            unit: 'Oct 24',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Feeding Events Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Feeding Events',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.textSecondary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Oct 1 - Oct 7',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Today's Date
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'TODAY, OCT 7',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Morning Feeding Card
                    _buildFeedingEventCard(
                      context,
                      time: '08:30 AM',
                      title: 'Morning Feeding',
                      subtitle: 'Automated Dispenser',
                      amount: '22.0',
                      unit: 'kg',
                      feedType: 'BioMar 2.0',
                      icon: Icons.water_drop,
                      iconColor: AppTheme.primaryColor,
                    ),

                    const SizedBox(height: 12),

                    // Afternoon Feeding Card
                    _buildFeedingEventCard(
                      context,
                      time: '02:15 PM',
                      title: 'Afternoon Feeding',
                      subtitle: 'Manual Check',
                      amount: '22.0',
                      unit: 'kg',
                      feedType: 'BioMar 2.0',
                      icon: Icons.cached,
                      iconColor: AppTheme.primaryColor,
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
    required String unit,
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFeedingEventCard(
    BuildContext context, {
    required String time,
    required String title,
    required String subtitle,
    required String amount,
    required String unit,
    required String feedType,
    required IconData icon,
    required Color iconColor,
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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Feeding Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $subtitle',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount and Feed Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    '$amount $unit',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                feedType,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}