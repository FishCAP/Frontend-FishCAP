import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/page_transitions.dart';
import '../../utils/responsive.dart';
import '../notifications/notifications_screen.dart';
import '../schedule/schedule_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../help/help_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _ponds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPonds();
  }

  Future<void> _fetchPonds() async {
    final result = await _apiService.getPonds();
    if (result['success'] == true && result['data'] is List) {
      setState(() => _ponds = result['data'] as List);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context);
    final bool desktop = ScreenHelper.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: desktop
            ? _buildDesktopLayout(context, l10n, userProvider)
            : _buildMobileLayout(context, l10n, userProvider),
      ),
      bottomNavigationBar: ScreenHelper.isMobile(context)
          ? _buildBottomNavBar(context, l10n)
          : null,
    );
  }

  Widget _buildDesktopLayout(BuildContext context, l10n, userProvider) {
    return Row(
      children: [
        // Left column: profile header
        SizedBox(
          width: 380,
          child: _buildProfileHeader(context, l10n, userProvider),
        ),
        // Right column: stats + preferences + actions
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ScreenHelper.horizontalPadding(context),
              vertical: 24,
            ),
            child: _buildDetails(context, l10n, userProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, l10n, userProvider) {
    final padding = ScreenHelper.horizontalPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      child: Column(
        children: [
          _buildProfileHeader(context, l10n, userProvider),
          const SizedBox(height: 24),
          _buildDetails(context, l10n, userProvider),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, l10n, userProvider) {
    final imageSize = ScreenHelper.profileImageSize(context);

    return Column(
      children: [
        // Header (title + notifications)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.profileTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  fontSize: ScreenHelper.fontSize(context, 24),
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

        const SizedBox(height: 8),

        // Profile Image
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor, width: 3),
              ),
              child: ClipOval(
                child: userProvider.user?.profileImage != null
                    ? Image.network(
                        userProvider.user!.profileImage!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.primaryColor,
                            child: Icon(
                              Icons.person,
                              size: imageSize * 0.5,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppTheme.primaryColor,
                        child: Icon(
                          Icons.person,
                          size: imageSize * 0.5,
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
                    PageTransitions.slideFromRight(const EditProfileScreen()),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Name
        Text(
          userProvider.user?.fullName ?? 'Loading...',
          style: TextStyle(
            fontSize: ScreenHelper.fontSize(context, 22),
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
            Expanded(
              child: Text(
                userProvider.user?.email ?? '',
                style: TextStyle(
                  fontSize: ScreenHelper.fontSize(context, 14),
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Phone
        if (userProvider.user?.phoneNumber != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  userProvider.user!.phoneNumber!,
                  style: TextStyle(
                    fontSize: ScreenHelper.fontSize(context, 14),
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetails(BuildContext context, l10n, userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Cards — responsive grid
        _buildStatsGrid(context, l10n),

        const SizedBox(height: 32),

        // Preferences Section
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.preferences.toUpperCase(),
            style: TextStyle(
              fontSize: ScreenHelper.fontSize(context, 12),
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Settings
        _buildPreferenceItem(
          context,
          icon: Icons.settings_outlined,
          title: l10n.settings,
          subtitle: l10n.appPreferences,
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.slideFromRight(const SettingsScreen()),
            );
          },
        ),

        const SizedBox(height: 12),

        // Help
        _buildPreferenceItem(
          context,
          icon: Icons.help_outline,
          title: l10n.help,
          subtitle: l10n.helpSubtitle,
          onTap: () {
            Navigator.push(
              context,
              PageTransitions.slideFromRight(const HelpScreen()),
            );
          },
        ),

        const SizedBox(height: 24),

        // Logout Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(context),
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
              side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, l10n) {
    final crossAxisCount = ScreenHelper.gridColumns(context);

    if (_isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
        ),
        itemCount: 2,
        itemBuilder: (context, index) => const _StatCardPlaceholder(),
      );
    }

    final tankCount = _ponds.length;
    final totalStock = _sumStock();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
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
            label: l10n.tanks,
            value: '$tankCount',
            color: AppTheme.primaryColor,
          );
        }
        return _buildStatCard(
          context,
          icon: Icons.inventory_2_outlined,
          label: l10n.stock,
          value: totalStock,
          color: AppTheme.secondaryColor,
        );
      },
    );
  }

  String _sumStock() {
    double total = 0;
    for (final pond in _ponds) {
      if (pond is Map<String, dynamic>) {
        final estCount = _parseDouble(pond['estCount'] ?? pond['initialCount']);
        if (estCount > 0) {
          total += estCount;
        }
      }
    }
    return '${total.toStringAsFixed(total % 1 == 0 ? 0 : 1)}kg';
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final fontSize = ScreenHelper.fontSize(context, 16);
    final valueFontSize = ScreenHelper.fontSize(context, 24);

    return Container(
      padding: EdgeInsets.all(
        ScreenHelper.responsive(context, 16, min: 12, max: 20),
      ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: ScreenHelper.responsive(context, 24, min: 20, max: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: fontSize, color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
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
    final fontSize = ScreenHelper.fontSize(context, 16);
    final subFontSize = ScreenHelper.fontSize(context, 13);

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
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subFontSize,
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

  Widget _buildBottomNavBar(BuildContext context, l10n) {
    return BottomNavigationBar(
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
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today, color: AppTheme.textSecondary),
          label: l10n.schedule,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history, color: AppTheme.textSecondary),
          label: l10n.history,
        ),
        BottomNavigationBarItem(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          label: l10n.profile,
        ),
      ],
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

class _StatCardPlaceholder extends StatelessWidget {
  const _StatCardPlaceholder();

  @override
  Widget build(BuildContext context) {
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
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
