import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../services/api_service.dart';
import '../../utils/page_transitions.dart';
import '../notifications/notifications_screen.dart';
import '../pond/create_pond_screen.dart';
import '../schedule/schedule_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService.instance;
  late Future<Map<String, dynamic>> _pondsFuture;
  List<dynamic> _allPonds = [];
  List<dynamic> _filteredPonds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pondsFuture = _fetchPonds();
  }

  Future<Map<String, dynamic>> _fetchPonds() async {
    final result = await _api.getPonds();
    if (result['success'] == true && result['data'] is List) {
      setState(() {
        _allPonds = result['data'] as List;
        _filteredPonds = _allPonds;
      });
    }
    return result;
  }

  void _filterPonds(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPonds = _allPonds;
      } else {
        _filteredPonds = _allPonds.where((pond) {
          final name = pond['name']?.toString().toLowerCase() ?? '';
          final species = pond['species']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) ||
              species.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final horizontalPadding = isWide ? 32.0 : 20.0;
            final pondCrossAxisCount = constraints.maxWidth >= 1000
                ? 3
                : constraints.maxWidth >= 650
                    ? 2
                    : 1;

            return FutureBuilder<Map<String, dynamic>>(
              future: _pondsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData ||
                    snapshot.data!['success'] != true) {
                  return Center(
                    child: Text(
                      snapshot.data?['message'] ?? 'Failed to load ponds',
                    ),
                  );
                } else {
                  return RefreshIndicator(
                    onRefresh: () async {
                      final result = await _fetchPonds();
                      if (result['success'] == true) {
                        _filterPonds(_searchQuery);
                      }
                    },
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(context, l10n),
                          const SizedBox(height: 24),

                          // Search Bar (now functional)
                          _buildSearchBar(),
                          const SizedBox(height: 20),

                          // Summary Cards Row
                          _buildSummaryCards(),
                          const SizedBox(height: 32),

                          // Your Sites Section
                          Text(
                            'Your Sites',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                          ),
                          const SizedBox(height: 16),

                          // Responsive Grid of Pond Cards
                          if (_filteredPonds.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('No ponds found'),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: pondCrossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: pondCrossAxisCount == 1
                                    ? 1.45
                                    : constraints.maxWidth >= 1000
                                        ? 1.1
                                        : 0.95,
                              ),
                              itemCount: _filteredPonds.length +
                                  1, // pond cards + add card
                              itemBuilder: (context, index) {
                                if (index == _filteredPonds.length) {
                                  return _buildAddPondCard(context);
                                }
                                final pond = _filteredPonds[index];
                                return _buildSiteCardFromPond(pond);
                              },
                            ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),

      // Custom Bottom Navigation (unchanged)
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ------------------ UI Helper Methods ------------------

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                PageTransitions.slideFromRight(const NotificationsScreen()),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
              onChanged: _filterPonds,
              decoration: const InputDecoration(
                hintText: 'Search ponds, species, or ID...',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final activePondsCount = _allPonds.length;
    final alertsCount = _allPonds.where((p) => p['hasAlert'] == true).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Active Ponds',
            value: '$activePondsCount',
            valueColor: AppTheme.textPrimary,
            icon: Icons.check_circle,
            iconColor: AppTheme.successColor,
            subtitle: 'All Running',
            subtitleColor: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Active Alerts',
            value: '$alertsCount',
            valueColor: AppTheme.errorColor,
            icon: Icons.warning_amber,
            iconColor: AppTheme.errorColor,
            subtitle: 'Attention Required',
            subtitleColor: AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    required String subtitle,
    required Color subtitleColor,
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
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds a pond card from a dynamic map (backend JSON)
  Widget _buildSiteCardFromPond(Map<String, dynamic> pond) {
    final id = pond['id']?.toString() ?? '';
    final name = pond['name']?.toString() ?? 'Unknown';
    final species = pond['species']?.toString() ?? 'Unknown';
    final status = pond['status']?.toString() ?? 'Unknown';
    final hasAlert = pond['hasAlert'] == true;

    // Determine status color: default to success if no alert, else error
    final statusColor = hasAlert ? AppTheme.errorColor : AppTheme.successColor;

    // Extract optional parameters
    String? ph;
    String? oxygen;
    String? temperature = pond['temperature']?.toString(); // may be null

    if (pond.containsKey('pH') && pond['pH'] != null) {
      ph = pond['pH'].toString() + ' pH';
    }
    if (pond.containsKey('oxygen') && pond['oxygen'] != null) {
      oxygen = pond['oxygen'].toString() + ' mg/L';
    }
    if (temperature == null) {
      temperature = '--°C'; // fallback
    }

    return _buildSiteCard(
      context,
      pondId: id,
      name: name,
      species: species,
      status: status,
      statusColor: statusColor,
      hasAlert: hasAlert,
      ph: ph,
      oxygen: oxygen,
      temperature: temperature,
    );
  }

  Widget _buildSiteCard(
    BuildContext context, {
    required String pondId,
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
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      species,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasAlert)
                      Icon(Icons.warning_amber, size: 14, color: statusColor),
                    if (hasAlert) const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ph != null) ...[
                const Icon(Icons.science, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  ph,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
              if (oxygen != null) ...[
                const Icon(Icons.air, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  oxygen,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
              const Icon(Icons.thermostat, size: 16, color: AppTheme.primaryColor),
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
                  PageTransitions.slideFromRight(
                    DashboardScreen(
                      pondId: pondId,
                      pondName: name,
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPondCard(BuildContext context) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: const Icon(Icons.add, color: AppTheme.primaryColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Need to add a pond?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Expand your operations by setting up a new monitoring site.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageTransitions.slideFromRight(const CreatePondScreen()),
                );
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
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