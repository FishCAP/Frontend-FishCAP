import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/user_provider.dart';
import '../../utils/page_transitions.dart';
import '../notifications/notifications_screen.dart';
import '../schedule/schedule_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);

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
                      Navigator.push(
                        context,
                        PageTransitions.slideFromRight(const NotificationsScreen()),
                      );
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adaptive horizontal padding: wider on tablets/desktop (>600px)
                  final isWide = constraints.maxWidth > 600;
                  final horizontalPadding = isWide ? 48.0 : 20.0;
                  // Stats cards: 2 columns on phones, 3+ on tablets
                  final statsCrossAxisCount = isWide ? 3 : 2;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                                child: userProvider.user?.profileImage != null
                                    ? Image.network(
                                        userProvider.user!.profileImage!,
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
                                      )
                                    : Container(
                                        color: AppTheme.primaryColor,
                                        child: Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                                  );
                                },
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
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Name - Dynamic from user data
                        Text(
                          userProvider.user?.fullName ?? 'Loading...',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Email
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                userProvider.user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Phone Number
                        if (userProvider.user?.phoneNumber != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  userProvider.user!.phoneNumber!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],

                        const SizedBox(height: 24),

                        // Stats Cards - responsive grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: statsCrossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.4,
                          ),
                          itemCount: 2,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildStatCard(
                                context,
                                icon: Icons.water_damage_outlined,
                                label: 'Tanks',
                                value: '12',
                                color: AppTheme.primaryColor,
                              );
                            }
                            return _buildStatCard(
                              context,
                              icon: Icons.inventory_2_outlined,
                              label: 'Stock',
                              value: '450kg',
                              color: AppTheme.secondaryColor,
                            );
                          },
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
                            Navigator.push(
                              context,
                              PageTransitions.slideFromRight(const SettingsScreen()),
                            );
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
                  );
                },
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
              Navigator.pushReplacement(
                context,
                PageTransitions.fade(const ScheduleScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                PageTransitions.fade(const HistoryScreen()),
              );
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
        mainAxisAlignment: MainAxisAlignment.center,
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);

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
            onPressed: () async {
              Navigator.pop(context);
              await userProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
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