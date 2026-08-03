import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';

class DashboardScreen extends StatelessWidget {
  final String pondName;
  final String species;

  const DashboardScreen({
    super.key,
    required this.pondName,
    required this.species,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                  ),
                  Expanded(
                    child: Text(
                      pondName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Info Cards Row
              Row(
                children: [
                  // Fish Count Card
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Fish Count',
                      '500',
                      Icons.people,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fish Type Card
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Fish Type',
                      'Tilapia',
                      Icons.eco,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Second Row of Info Cards
              Row(
                children: [
                  // Stocking Duration Card
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Stocking Duration',
                      'Day 45',
                      Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expected Harvest Card
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Expected Harvest',
                      'Oct 24, 2026',
                      Icons.event_available,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Alert Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
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
                            'Low Feed Level (0.8kg)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Feeder contains less than 1kg of feed',
                            style: TextStyle(
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
                    child: _buildQualityCard(
                      context,
                      'Oxygen (O2)',
                      '6.5',
                      'mg/L',
                      AppTheme.successColor,
                      'Optimal',
                      Icons.air,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Temperature Card
                  Expanded(
                    child: _buildQualityCard(
                      context,
                      'Temp',
                      '28.4°C',
                      '',
                      AppTheme.successColor,
                      'Optimal',
                      Icons.thermostat,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // pH Level Card
                  Expanded(
                    child: _buildQualityCard(
                      context,
                      'pH Level',
                      '6.8',
                      '',
                      AppTheme.errorColor,
                      'Warning',
                      Icons.science,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Active Monitoring Image Card
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&q=80',
                    ),
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
                        Colors.black.withOpacity(0.7),
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
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
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

              // Morning Feed
              _buildFeedScheduleItem(
                context,
                time: '8:00 AM',
                label: 'Morning Feed',
                status: 'Pending',
                statusColor: AppTheme.successColor,
                icon: Icons.access_time,
              ),

              const SizedBox(height: 12),

              // Evening Feed
              _buildFeedScheduleItem(
                context,
                time: '4:00 PM',
                label: 'Evening Feed',
                status: 'Scheduled',
                statusColor: AppTheme.primaryColor,
                icon: Icons.schedule,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                Navigator.pushNamed(context, '/schedule');
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.history,
              label: 'History',
              isSelected: false,
              onTap: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
            _buildNavItem(
              context,
              icon: Icons.person,
              label: 'Profile',
              isSelected: false,
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ),
    );
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
            color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.05),
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
              color: AppTheme.primaryColor.withOpacity(0.1),
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
              color: statusColor.withOpacity(0.1),
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
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
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