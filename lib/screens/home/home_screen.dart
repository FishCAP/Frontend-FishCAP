import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
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

              const SizedBox(height: 24),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search ponds, species, or ID...',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
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
                            color: Colors.black.withOpacity(0.05),
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
                            color: Colors.black.withOpacity(0.05),
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

              // Add New Pond Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
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

              const SizedBox(height: 100), // Space for bottom navigation
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
            color: Colors.black.withOpacity(0.05),
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
                  color: statusColor.withOpacity(0.1),
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
                    builder: (context) => DashboardScreen(
                      pondName: name,
                      species: species,
                    ),
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