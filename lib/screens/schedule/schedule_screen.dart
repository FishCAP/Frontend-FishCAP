import 'package:fishcap_app/screens/home/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../utils/page_transitions.dart';
import '../../models/pond.dart';
import '../../services/api_service.dart';
import '../../services/notification_badge.dart';
import '../notifications/notifications_screen.dart';
import '../pond/create_pond_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ApiService _apiService = ApiService.instance;
  List<Pond> _ponds = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPonds();
      }
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadPonds() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.loadToken();

      final result = await _apiService.getPonds();

      if (!mounted) return;

      if (result['success'] != true) {
        setState(() {
          _errorMessage =
              result['message']?.toString() ?? l10n.failedToLoadPonds;
          _isLoading = false;
        });
        return;
      }

      final rawData = result['data'];

      if (rawData == null) {
        setState(() {
          _ponds = [];
          _isLoading = false;
        });
        return;
      }

      List<dynamic> pondsList;

      // API may return:
      // data: [...]
      if (rawData is List) {
        pondsList = rawData;
      }
      // Or:
      // data: { items: [...] }
      else if (rawData is Map && rawData['items'] is List) {
        pondsList = rawData['items'] as List;
      } else {
        pondsList = [];
      }

      final List<Pond> loaded = [];

      for (final item in pondsList) {
        if (item is! Map) continue;

        try {
          final json = Map<String, dynamic>.from(item);
          final pond = Pond.fromJson(json);

          loaded.add(pond);

          debugPrint(
            '[Schedule] Pond loaded: '
            'id=${pond.id}, '
            'name=${pond.name}, '
            'status=${pond.status}',
          );
        } catch (e) {
          debugPrint('[Schedule] Invalid pond skipped: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _ponds = loaded;
        _isLoading = false;
      });

      debugPrint(
        '[Schedule] Total ponds=${_ponds.length}, '
        'active=${_activePonds.length}',
      );
    } catch (e, stackTrace) {
      debugPrint('[Schedule] Load error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error loading ponds: $e';
        _isLoading = false;
      });
    }
  }

  /// Ponds that are still active (i.e. NOT done/completed).
  ///
  /// Only active ponds are shown on the Schedule screen. Ponds that have been
  /// marked as done live in the History screen instead, so they are filtered
  /// out here.
  List<Pond> get _activePonds {
    return _ponds.where((pond) {
      final status = pond.status.trim().toLowerCase();

      // Only these statuses should go to History.
      const doneStatuses = {'done', 'completed', 'complete', 'finished'};

      return !doneStatuses.contains(status);
    }).toList();
  }

  List<Pond> get _visiblePonds {
    if (_searchQuery.isEmpty) return _activePonds;
    return _activePonds.where((p) {
      final name = p.name.toLowerCase();
      final species = p.species.toLowerCase();
      return name.contains(_searchQuery) || species.contains(_searchQuery);
    }).toList();
  }

  Future<void> _deletePond(Pond pond) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePond),
        content: Text(
          'Are you sure you want to delete "${pond.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.deletePond(pond.id);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pond.name} deleted successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      await _loadPonds();
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? l10n.failedToDeletePond),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _editPond(Pond pond) async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      PageTransitions.slideFromRight(CreatePondScreen(pond: pond)),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadPonds();
    }
  }

  Future<void> _navigateToCreatePond() async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      PageTransitions.slideFromRight(const CreatePondScreen()),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadPonds();
    }
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
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    ),
                  ),

                  // Notification Bell with unread badge
                  ValueListenableBuilder<int>(
                    valueListenable: unreadNotificationCount,
                    builder: (context, unread, _) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
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
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppTheme.errorColor,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                    // Search Bar (filters ponds by name or species)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search ponds, species, or ID...',
                                hintStyle: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                              onSubmitted: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    LayoutBuilder(
                      builder: (context, summaryConstraints) {
                        final compact = summaryConstraints.maxWidth < 360;
                        final cards = [
                          _buildSummaryCard(
                            context,
                            label: l10n.activePonds,
                            value: '${_activePonds.length}',
                            detail: 'All running',
                            icon: Icons.check_circle,
                            color: AppTheme.successColor,
                          ),
                          _buildSummaryCard(
                            context,
                            label: 'Active Alerts',
                            value:
                                '${_activePonds.where((p) => p.hasAlert).length}',
                            detail: 'Needs attention',
                            icon: Icons.warning_amber,
                            color: AppTheme.errorColor,
                          ),
                        ];
                        return compact
                            ? Column(
                                children: [
                                  cards.first,
                                  const SizedBox(height: 12),
                                  cards.last,
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: cards.first),
                                  const SizedBox(width: 12),
                                  Expanded(child: cards.last),
                                ],
                              );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Your Sites Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Sites',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Loading State
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    // Error State
                    else if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadPonds,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    // Empty State: no ponds at all
                    else if (_activePonds.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.water_damage_outlined,
                                size: 64,
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No active ponds',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ponds you mark as Done move to History',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    // No matches for current filter
                    else if (_visiblePonds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text('No ponds match your search')),
                      )
                    // Ponds List (filtered)
                    else
                      ...List.generate(_visiblePonds.length, (index) {
                        final pond = _visiblePonds[index];
                        return Column(
                          children: [
                            _buildSiteCard(context, pond),
                            if (index < _visiblePonds.length - 1)
                              const SizedBox(height: 16),
                          ],
                        );
                      }),

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
                              onPressed: _navigateToCreatePond,
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

                    const SizedBox(
                      height: 100,
                    ), // Space for bottom navigation and FAB
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
              Navigator.pushReplacement(
                context,
                PageTransitions.fade(const HistoryScreen()),
              );
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
            label: l10n.schedule,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history, color: AppTheme.textSecondary),
            label: l10n.history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person, color: AppTheme.textSecondary),
            label: l10n.profile,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePond,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSiteCard(BuildContext context, Pond pond) {
    final l10n = AppLocalizations.of(context)!;
    // Safely parse status color, fallback to primary if null or invalid
    Color statusColor;
    try {
      if (pond.statusColor.isNotEmpty) {
        statusColor = Color(
          int.parse(pond.statusColor.replaceFirst('#', '0xFF')),
        );
      } else {
        statusColor = AppTheme.primaryColor;
      }
    } catch (_) {
      statusColor = AppTheme.primaryColor;
    }

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
                constraints: const BoxConstraints(maxWidth: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pond.name,
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
                      pond.species,
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
              _buildStatusChip(pond, statusColor),
            ],
          ),
          const SizedBox(height: 16),
          // Display only fields that exist in the Pond model
          Row(
            children: [
              // Temperature is always present in the model
              Icon(Icons.thermostat, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                pond.temperature,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              // Add other fields if they exist in the model (they are not in the given Pond definition)
              // If you have ph and oxygen in your model, uncomment:
              // if (pond.ph != null) ...[
              //   const SizedBox(width: 16),
              //   Icon(Icons.science, size: 16, color: AppTheme.primaryColor),
              //   const SizedBox(width: 6),
              //   Text(pond.ph!, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
              // ],
              // if (pond.oxygen != null) ...[
              //   const SizedBox(width: 16),
              //   Icon(Icons.water_damage, size: 16, color: AppTheme.errorColor),
              //   const SizedBox(width: 6),
              //   Text(pond.oxygen!, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
              // ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        PageTransitions.slideFromRight(
                          DashboardScreen(pondId: pond.id, pondName: pond.name),
                        ),
                      );
                      // A pond can be toggled to "Done" from its dashboard; when
                      // that happens it moves to History, so refresh the active
                      // list here.
                      if (!mounted) return;
                      if (result == true && mounted) {
                        await _loadPonds();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.viewDashboard,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _editPond(pond),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    foregroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.edit, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _deletePond(pond),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.delete, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Pond pond, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pond.hasAlert)
            Icon(Icons.warning_amber, size: 14, color: statusColor),
          if (pond.hasAlert) const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              pond.status,
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
    );
  }
}
