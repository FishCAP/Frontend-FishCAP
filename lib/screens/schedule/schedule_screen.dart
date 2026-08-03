import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../history/history_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

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
                  // Profile Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  // App Title
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.appName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                  ),

                  // Notification Bell
                  Container(
                    width: 48,
                    height: 48,
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
                                hintText: 'Search ponds, species, or ID...',
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

                    const SizedBox(height: 20),

                    // Summary Cards Row
                    Row(
                      children: [
                        // Active Ponds Card
                        Expanded(
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
                                Text(
                                  'Active Ponds',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '12',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: AppTheme.successColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'All Running',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Active Alerts Card
                        Expanded(
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
                                Text(
                                  'Active Alerts',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '03',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.errorColor,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      size: 16,
                                      color: AppTheme.errorColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Attention Required',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.errorColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Your Sites Section
                    Text(
                      'Your Sites',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),

                    const SizedBox(height: 16),

                    // Lake A Site Card
                    _buildSiteCard(
                      context,
                      name: 'Lake A',
                      species: 'Atlantic Salmon • Gen-4',
                      ph: '7.4 pH',
                      temperature: '14.2°C',
                      status: 'Optimal',
                      statusColor: AppTheme.successColor,
                      hasAlert: false,
                    ),

                    const SizedBox(height: 16),

                    // Nursery 01 Site Card
                    _buildSiteCard(
                      context,
                      name: 'Nursery 01',
                      species: 'Pacific White Shrimp • Post-Larval',
                      oxygen: '2.1 mg/L',
                      temperature: '28.5°C',
                      status: 'Low Oxygen',
                      statusColor: AppTheme.errorColor,
                      hasAlert: true,
                    ),

                    const SizedBox(height: 16),

                    // Raceway 4 Site Card
                    _buildSiteCard(
                      context,
                      name: 'Raceway 4',
                      species: 'Rainbow Trout • Juvenile',
                      ph: '--',
                      temperature: '11.8°C',
                      status: 'Draining',
                      statusColor: AppTheme.warningColor,
                      hasAlert: false,
                    ),

                    const SizedBox(height: 20),

                    // Add New Pond Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7F7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Need to add a pond?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Expand your operations by setting up a new monitoring site.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/create_pond');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D7377),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '+ Add Site',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Space for bottom navigation and FAB
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create_pond');
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSiteCard(
    BuildContext context, {
    required String name,
    required String species,
    required String status,
    required Color statusColor,
    bool hasAlert = false,
    String? ph,
    String? oxygen,
    required String temperature,
  }) {
    return Container(
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
              if (ph != null) ...[
                Icon(
                  Icons.science,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  ph,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              if (oxygen != null) ...[
                Icon(
                  Icons.water_damage,
                  size: 16,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: 6),
                Text(
                  oxygen,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Icon(
                Icons.thermostat,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                temperature,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PondHistoryDetailScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}