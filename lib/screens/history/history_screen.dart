import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../utils/page_transitions.dart';
import '../../services/api_service.dart';
import '../notifications/notifications_screen.dart';
import '../schedule/schedule_screen.dart';
import '../profile/profile_screen.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
        // The History screen only shows ponds that have been marked as
        // Done/Completed (i.e. they have "moved to history"). Active ponds
        // are displayed on the Schedule screen instead.
        _allPonds = (result['data'] as List)
            .where((pond) => pond is Map<String, dynamic> && _isPondDone(pond))
            .toList();
        _filteredPonds = _allPonds;
      });
    }
    return result;
  }

  /// Returns true when a pond's status marks it as Done/Completed.
  static bool _isPondDone(Map<String, dynamic> pond) {
    final status = (pond['status']?.toString() ?? 'active').toLowerCase();
    return status == 'done' || status == 'completed' || status == 'finished';
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
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransitions.slideFromRight(
                          const NotificationsScreen(),
                        ),
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
              child: FutureBuilder<Map<String, dynamic>>(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
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
                                      decoration: InputDecoration(
                                        hintText:
                                            'Search by name or species...',
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

                            // Stats Cards (dynamic)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    title: 'COMPLETED PONDS',
                                    value: '${_allPonds.length}',
                                    valueColor: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    context,
                                    title: 'ALERTS',
                                    value:
                                        '${_allPonds.where((p) => p['hasAlert'] == true).length}',
                                    valueColor: AppTheme.errorColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Pond Cards (dynamic)
                            if (_filteredPonds.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('No completed ponds yet'),
                                ),
                              )
                            else
                              ..._filteredPonds.map((pond) {
                                final name =
                                    pond['name']?.toString() ?? 'Unknown';
                                final species =
                                    pond['species']?.toString() ?? 'Unknown';
                                final status =
                                    pond['status']?.toString() ?? 'Unknown';
                                final hasAlert = pond['hasAlert'] == true;
                                final pondId = pond['id']?.toString() ?? '';
                                final iconTypes =
                                    (pond['iconTypes'] as List<dynamic>?) ??
                                    const [];

                                return Column(
                                  children: [
                                    _buildPondHistoryCard(
                                      context,
                                      name: name,
                                      species: species,
                                      status: status,
                                      statusColor: hasAlert
                                          ? AppTheme.errorColor
                                          : AppTheme.successColor,
                                      hasAlert: hasAlert,
                                      icons: _buildIconsFromTypes(iconTypes),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                HistoryDetailScreen(
                                                  pondId: pondId,
                                                  pondName: name,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                );
                              }),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                PageTransitions.fade(const ScheduleScreen()),
              );
              break;
            case 1:
              // Already on history
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                PageTransitions.fade(const ProfileScreen()),
              );
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
              child: const Icon(Icons.history, color: Colors.white, size: 24),
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person, color: AppTheme.textSecondary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  List<Icon> _buildIconsFromTypes(List<dynamic> types) {
    return types.map((type) {
      switch (type.toString()) {
        case 'water':
        case 'water_drop':
          return Icon(Icons.water_drop, size: 16, color: AppTheme.primaryColor);
        case 'temp':
        case 'thermostat':
          return Icon(Icons.thermostat, size: 16, color: AppTheme.primaryColor);
        case 'science':
        case 'chemistry':
          return Icon(Icons.science, size: 16, color: AppTheme.primaryColor);
        case 'alert':
        case 'warning':
          return Icon(
            Icons.warning_amber,
            size: 16,
            color: AppTheme.errorColor,
          );
        default:
          return Icon(
            Icons.info_outline,
            size: 16,
            color: AppTheme.primaryColor,
          );
      }
    }).toList();
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      if (hasAlert)
                        Icon(Icons.warning_amber, size: 14, color: statusColor),
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
