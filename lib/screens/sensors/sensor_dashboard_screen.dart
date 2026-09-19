import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../models/sensor_data.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';

class SensorDashboardScreen extends StatefulWidget {
  const SensorDashboardScreen({super.key});

  @override
  State<SensorDashboardScreen> createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends State<SensorDashboardScreen> {
  final ApiService _apiService = ApiService.instance;
  List<SensorData> _sensorData = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _sensorSub;

  @override
  void initState() {
    super.initState();
    _fetchSensorData();
    // Poll every 30 seconds as a fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchSensorData();
    });
    // Listen to WebSocket sensor_update stream for immediate refresh
    _sensorSub = RealtimeService.instance.sensorDataStream.listen((_) {
      _fetchSensorData();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _sensorSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchSensorData() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await _apiService.getLatestSensorData();
      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        if (data is List) {
          setState(() {
            _sensorData = data
                .map((e) => SensorData.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
            _isLoading = false;
            _error = null;
          });
        } else if (data is Map) {
          // Single object response
          setState(() {
            _sensorData = [SensorData.fromJson(Map<String, dynamic>.from(data))];
            _isLoading = false;
            _error = null;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = result['message'] ?? l10n.failedToLoadPonds;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = l10n.networkError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sensorDashboard),
        actions: [
          IconButton(
            onPressed: _fetchSensorData,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final horizontalPadding = isWide ? 32.0 : 16.0;
            final crossAxisCount = isWide ? 3 : 2;

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_error != null && _sensorData.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sensors_off,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.errorColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchSensorData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_sensorData.isEmpty) {
              return const Center(
                child: Text(
                  'No sensor data yet.\nWaiting for ESP32 device...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }

            final latest = _sensorData.first;

            return SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Latest readings header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Readings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      if (latest.createdAt != null)
                        Text(
                          _formatTime(latest.createdAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sensor value cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _buildSensorCard(
                            context,
                            label: 'Temperature',
                            value: latest.temperature?.toStringAsFixed(1) ?? '--',
                            unit: l10n.temperature,
                            icon: Icons.thermostat,
                            color: AppTheme.primaryColor,
                          );
                        case 1:
                          return _buildSensorCard(
                            context,
                            label: 'pH Level',
                            value: latest.ph?.toStringAsFixed(2) ?? '--',
                            unit: '',
                            icon: Icons.science,
                            color: AppTheme.secondaryColor,
                          );
                        case 2:
                          return _buildSensorCard(
                            context,
                            label: 'TDS',
                            value: latest.tds?.toStringAsFixed(1) ?? '--',
                            unit: 'ppm',
                            icon: Icons.water_drop,
                            color: AppTheme.successColor,
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // Device info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.memory,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Device ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                latest.deviceId,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // History section
                  Text(
                    'Recent History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),

                  const SizedBox(height: 16),

                  // History list
                  ..._sensorData.take(10).map((data) {
                    return _buildHistoryItem(context, data);
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSensorCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildHistoryItem(BuildContext context, SensorData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.createdAt != null ? _formatTime(data.createdAt!) : '--',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                                    'Temp: ${data.temperature?.toStringAsFixed(1) ?? '--'}°C  •  pH: ${data.ph?.toStringAsFixed(2) ?? '--'}  •  TDS: ${data.tds?.toStringAsFixed(1) ?? '--'} ppm',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}