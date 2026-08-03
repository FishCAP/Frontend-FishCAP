import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  Text(
                    l10n.profileTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
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
                  children: [
                    // Profile Image with Edit Button
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=240&h=240&fit=crop',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.primaryColor,
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Name
                    const Text(
                      'Sok Chamroeun',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Phone Number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '+855 12 345 678',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Phnom Penh',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            icon: Icons.water_damage_outlined,
                            label: 'Tanks',
                            value: '12',
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            icon: Icons.inventory_2_outlined,
                            label: 'Stock',
                            value: '450kg',
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Preferences Section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PREFERENCES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Settings Option
                    _buildPreferenceItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App & notification preferences',
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),

                    const SizedBox(height: 12),

                    // Help Option
                    _buildPreferenceItem(
                      context,
                      icon: Icons.help_outline,
                      title: 'Help',
                      subtitle: 'FAQs & Support center',
                      onTap: () {
                        // Navigate to help
                      },
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showLogoutDialog(context);
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                        label: Text(
                          l10n.logout,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(
                            color: AppTheme.errorColor,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/schedule');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/history');
              break;
            case 2:
              // Already on profile
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
            icon: const Icon(Icons.history_outlined),
            activeIcon: Icon(
              Icons.history,
              color: AppTheme.textSecondary,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
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
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildPreferenceItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text(
              l10n.yes,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}