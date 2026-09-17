import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../models/pond.dart';
import '../../services/api_service.dart';
import '../../widgets/hardware_id_action_button.dart';
import 'package:intl/intl.dart';

class CreatePondScreen extends StatefulWidget {
  final Pond? pond;

  const CreatePondScreen({super.key, this.pond});

  @override
  State<CreatePondScreen> createState() => _CreatePondScreenState();
}

class _CreatePondScreenState extends State<CreatePondScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteLocationController = TextEditingController();
  final _speciesController = TextEditingController();
  final _estCountController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _hardwareIdController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  // Alert info fetched from backend for existing ponds
  bool _hasAlert = false;
  String _alertTitle = '';
  String _alertMessage = '';

  // ── Hardware binding state ────────────────────────────────────────
  // The backend binds hardware through the `devices` table only: the pond
  // payload must carry `deviceId` (the device row's UUID) so it takes the
  // createWithDevice()/assign lifecycle. A free-typed label alone used to
  // be sent as `hardwareId`, which never touches devices.pond_id — the
  // ESP32 polls schedules ONLY via devices.pond_id, so that binding is
  // what makes feeding work.
  List<Map<String, dynamic>> _availableDevices = [];
  bool _loadingDevices = false;
  String? _selectedDeviceId;
  String? _selectedDeviceCode;

  /// The device bound to the pond when the edit form opened, so a changed
  /// selection can be pushed with POST /devices/:id/assign after the update.
  String? _originalDeviceId;

  // Each feeding schedule has its own time and amount.
  final List<Map<String, dynamic>> _feedingSchedules = [];

  @override
  void initState() {
    super.initState();
    if (widget.pond != null) {
      _loadPondData(widget.pond!);
      _fetchPondAlerts();
    }
    _refreshAvailableDevices();
  }

  /// Loads devices the form can offer for binding:
  /// - `GET /api/devices/available` for the picker (unbound hardware), and
  /// - for edit mode, resolves the pond's CURRENT device (by its
  ///   `hardwareId` label) from the full registry so the UI can preselect
  ///   it and detect a changed selection.
  Future<void> _refreshAvailableDevices() async {
    if (!mounted) return;
    setState(() => _loadingDevices = true);
    try {
      final api = ApiService.instance;
      final result = await api.getAvailableDevices();
      if (!mounted) return;
      if (result['success'] == true && result['data'] is List) {
        _availableDevices = (result['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      // Edit mode: find which registered device row (if any) matches the
      // pond's current hardware label so we can reuse its UUID.
      final label = (widget.pond?.hardwareId ?? _selectedDeviceCode ?? '')
          .toString()
          .trim();
      if (widget.pond != null &&
          label.isNotEmpty &&
          _selectedDeviceId == null) {
        final all = await api.getDevices();
        if (!mounted) return;
        if (all['success'] == true && all['data'] is List) {
          for (final device in (all['data'] as List).whereType<Map>()) {
            final code = device['deviceCode']?.toString() ?? '';
            if (code.toLowerCase() == label.toLowerCase()) {
              setState(() {
                _selectedDeviceId = device['id']?.toString();
                _originalDeviceId = _selectedDeviceId;
              });
              break;
            }
          }
        }
      }
    } catch (_) {
      // Non-fatal: the picker shows an empty state with a Refresh button.
    } finally {
      if (mounted) setState(() => _loadingDevices = false);
    }
  }

  /// Applies a selection made in the HardwareIdDialog.
  ///
  /// `selection.deviceId` is set when the user picked/generated a registered
  /// device; a manually typed label arrives with only `hardwareId`, in which
  /// case the device is registered during save (see _resolveOrCreateDevice).
  void _applyHardwareSelection(HardwareIdSelection selection) {
    setState(() {
      _selectedDeviceId = selection.deviceId;
      _selectedDeviceCode = selection.hardwareId?.trim();
      _hardwareIdController.text = _selectedDeviceCode ?? '';
    });
  }

  /// Maps a hardware label to a registered device UUID so the pond payload
  /// can carry `deviceId`.
  ///
  /// Order:
  /// 1. Register the device (POST /api/sensors/devices) — covers brand-new
  ///    hardware labels typed by the user.
  /// 2. On failure (e.g. the code already exists), look the device up in the
  ///    registry (GET /api/devices) and reuse it when it is unbound or
  ///    already bound to this very pond.
  /// Returns (deviceId, errorMessage); exactly one of the two is non-null.
  Future<(String?, String?)> _resolveOrCreateDevice(String label) async {
    final api = ApiService.instance;
    final created = await api.createDevice(deviceCode: label);
    if (created['success'] == true && created['data'] is Map) {
      final data = created['data'] as Map;
      final id = data['id']?.toString();
      if (id != null && id.isNotEmpty) {
        // Make it appear in the picker's registry next time.
        _refreshAvailableDevices();
        return (id, null);
      }
    }

    // Registration failed — most likely the device code already exists.
    final listed = await api.getDevices();
    if (listed['success'] == true && listed['data'] is List) {
      for (final device in (listed['data'] as List).whereType<Map>()) {
        final code = device['deviceCode']?.toString() ?? '';
        if (code.toLowerCase() == label.toLowerCase()) {
          final id = device['id']?.toString();
          final boundPond =
              (device['pondId'] ?? device['pond_id'])?.toString();
          final isFree = boundPond == null || boundPond.isEmpty;
          final isOurs =
              widget.pond != null && boundPond == widget.pond!.id;
          if (id != null && id.isNotEmpty && (isFree || isOurs)) {
            return (id, null);
          }
          return (
            null,
            'Hardware "$label" is already assigned to another pond. Complete that pond first or choose different hardware.'
          );
        }
      }
    }
    return (null, created['message']?.toString() ?? 'Failed to register hardware "$label"');
  }

  Future<void> _fetchPondAlerts() async {
    if (widget.pond == null) return;
    try {
      final api = ApiService.instance;
      final res = await api.getPondById(widget.pond!.id);
      if (res['success'] == true && res['data'] is Map<String, dynamic>) {
        final data = res['data'] as Map<String, dynamic>;
        final title = data['alertTitle']?.toString() ?? '';
        final message = data['alertMessage']?.toString() ?? '';
        if (mounted) {
          setState(() {
            _hasAlert = title.isNotEmpty || message.isNotEmpty;
            _alertTitle = title;
            _alertMessage = message;
          });
        }
      }
    } catch (_) {}
  }

  /// Average weight per fish (grams) used for the recommended-feeding
  /// calculator. Default assumes a medium-sized fish (e.g. 250 g).
  final double _avgWeightPerFishGrams = 250;

  /// Daily feeding percentage of body weight. Typical aquaculture range:
  /// 2-3% of body weight per day. We use 3% as the default recommendation.
  final double _dailyFeedPercent = 3.0;

  /// Whether the recommended-feeding calculator has been applied.
  bool _showRecommended = false;

  /// Recompute the recommended feeding numbers based on estimated count,
  /// average weight, and daily feed percentage.
  (int totalFish, double totalBiomassKg, double dayFeedKg,
      double perFeedKg, int mealCount)
      _computeRecommended() {
    final estCount = int.tryParse(_estCountController.text.trim());
    final totalFish = estCount ?? 0;
    if (totalFish <= 0) {
      return (0, 0.0, 0.0, 0.0, 3);
    }
    final totalBiomassKg = (totalFish * _avgWeightPerFishGrams) / 1000.0;
    final dayFeedKg = totalBiomassKg * (_dailyFeedPercent / 100.0);
    final mealCount = 3;
    final perFeedKg = dayFeedKg / mealCount;
    return (totalFish, totalBiomassKg, dayFeedKg, perFeedKg, mealCount);
  }

  /// Apply the currently computed recommendation to the feeding schedules.
  ///
  /// If there are no feeding times yet, inserts 3 default daily feeding
  /// times (08:00, 13:00, 18:00) with the per-meal recommended amount.
  /// Otherwise, updates every existing schedule entry to the recommended
  /// per-meal amount.
  void _applyRecommended() {
    final (_, _, _, perFeedKg, _) = _computeRecommended();
    if (perFeedKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add an estimated fish count first to see a recommendation.',
          ),
        ),
      );
      _showRecommended = false;
      return;
    }

    final existingTimes = _feedingSchedules
        .map((item) => item['time'] as String)
        .toList();

    if (existingTimes.isEmpty) {
      setState(() {
        _feedingSchedules.clear();
        _feedingSchedules.addAll([
          {'time': '08:00', 'amount': perFeedKg},
          {'time': '13:00', 'amount': perFeedKg},
          {'time': '18:00', 'amount': perFeedKg},
        ]);
      });
    } else {
      setState(() {
        for (final item in _feedingSchedules) {
          item['amount'] = perFeedKg;
        }
      });
    }
    _showRecommended = true;
  }

  /// Show a short summary of the current recommendation (for display in the
  /// UI card).
  String _recommendedSummary() {
    final (fish, biomass, dayFeed, perFeed, meals) =
        _computeRecommended();
    if (fish <= 0) {
      return 'Enter estimated fish count to calculate a recommendation.';
    }
    return '$fish fish  •  ${biomass.toStringAsFixed(1)} kg biomass  '
        '•  $dayFeed kg/day  •  $perFeed kg/feed  •  $meals meals';
  }

  void _loadPondData(Pond pond) {
    _siteLocationController.text = pond.location ?? pond.name;
    _speciesController.text = pond.species;
    _estCountController.text = pond.estimatedCount?.toString() ?? '';

    if (pond.startDate != null && pond.startDate!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(pond.startDate!);
        _startDateController.text = DateFormat('MM/dd/yyyy').format(parsed);
        _startDate = parsed;
      } catch (_) {
        _startDateController.text = pond.startDate!;
      }
    }

    if (pond.endDate != null && pond.endDate!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(pond.endDate!);
        _endDateController.text = DateFormat('MM/dd/yyyy').format(parsed);
        _endDate = parsed;
      } catch (_) {
        _endDateController.text = pond.endDate!;
      }
    }

    _hardwareIdController.text = pond.hardwareId ?? '';
    _selectedDeviceCode = pond.hardwareId;

    // Older data only contains feedingTimes. Use pond.amount as a fallback
    // amount for those existing schedules.
    final oldAmount = pond.amount ?? 0;
    if (pond.feedingTimes != null) {
      for (final time in pond.feedingTimes!) {
        _feedingSchedules.add({'time': time, 'amount': oldAmount});
      }
    }
  }

  @override
  void dispose() {
    _siteLocationController.dispose();
    _speciesController.dispose();
    _estCountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _hardwareIdController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat('MM/dd/yyyy').format(picked);

        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
          _endDateController.clear();
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _showAddFeedingDialog() async {
    TimeOfDay? selectedTime;
    final amountController = TextEditingController();
    final timeController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Feeding Schedule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Feeding Time',
                      hintText: 'Select time',
                      prefixIcon: const Icon(Icons.access_time),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.schedule),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedTime = picked;
                              timeController.text = picked.format(
                                dialogContext,
                              );
                            });
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: timeController,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedTime = picked;
                          timeController.text = picked.format(dialogContext);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      suffixText: 'kg',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedTime == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Please select a time')),
                      );
                      return;
                    }

                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                      return;
                    }

                    final serverTime =
                        '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

                    Navigator.pop(dialogContext, {
                      'time': serverTime,
                      'amount': amount,
                    });
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    timeController.dispose();

    if (result == null || !mounted) return;

    final newTime = result['time'] as String;
    final newAmount = (result['amount'] as num).toDouble();

    final alreadyExists = _feedingSchedules.any(
      (item) => item['time'] == newTime,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feeding time already exists')),
      );
      return;
    }

    setState(() {
      _feedingSchedules.add({'time': newTime, 'amount': newAmount});
      _feedingSchedules.sort(
        (a, b) => (a['time'] as String).compareTo(b['time'] as String),
      );
    });
  }

  void _removeFeedingSchedule(int index) {
    setState(() => _feedingSchedules.removeAt(index));
  }

  String _formatTime(String value) {
    try {
      final parts = value.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final time = TimeOfDay(hour: hour, minute: minute);
      return time.format(context);
    } catch (_) {
      return value;
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    if (_feedingSchedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one feeding time')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final apiService = ApiService.instance;
    final pondData = <String, dynamic>{
      'name': _siteLocationController.text.trim(),
      'location': _siteLocationController.text.trim(),
      'species': _speciesController.text.trim(),
    };

    final estCount = int.tryParse(_estCountController.text.trim());
    if (estCount != null) pondData['estimatedCount'] = estCount;

    if (_startDate != null) {
      pondData['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      pondData['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    }

    // Keep the old feedingTimes field for compatibility with the current API,
    // and also send the new per-time amount data.
    pondData['feedingTimes'] = _feedingSchedules
        .map((item) => item['time'] as String)
        .toList();
    pondData['feedingSchedules'] = _feedingSchedules
        .map((item) => {'time': item['time'], 'amount': item['amount']})
        .toList();

    // Keep amount populated for compatibility with the existing Pond model/API.
    final totalAmount = _feedingSchedules.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );
    pondData['amount'] = totalAmount;

    // ── Hardware → deviceId resolution ────────────────────────────────
    // The ESP32 polls schedules ONLY via devices.pond_id, so the pond must
    // be created/updated with a real deviceId (device row UUID). A plain
    // hardwareId string would take the legacy create() path that never
    // touches the devices table and would leave the feeder unbound.
    final hardwareLabel =
        (_selectedDeviceCode ?? _hardwareIdController.text).trim();
    if (hardwareLabel.isNotEmpty) {
      // Keep the legacy display label alongside the binding.
      pondData['hardwareId'] = hardwareLabel;
    }

    String? deviceId = _selectedDeviceId;
    if (hardwareLabel.isNotEmpty && deviceId == null) {
      final (resolvedId, resolveError) =
          await _resolveOrCreateDevice(hardwareLabel);
      if (!mounted) return;
      if (resolveError != null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resolveError),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      deviceId = resolvedId;
      _selectedDeviceId = deviceId;
    }

    // Creation: include deviceId so the backend takes the createWithDevice()
    // path, which validates availability and binds devices.pond_id.
    // Update: UpdatePondDto has no deviceId field (the whitelist would 400);
    // a changed binding is pushed separately via POST /devices/:id/assign.
    if (deviceId != null && widget.pond == null) {
      pondData['deviceId'] = deviceId;
    }

    Map<String, dynamic> result;
    try {
      if (widget.pond != null) {
        result = await apiService.updatePond(widget.pond!.id, pondData);
      } else {
        result = await apiService.createPond(pondData);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Edit mode: bind/rebind the hardware after the pond row was saved.
      if (widget.pond != null &&
          deviceId != null &&
          deviceId != _originalDeviceId) {
        final assignResult =
            await apiService.assignDevice(deviceId, widget.pond!.id);
        if (!mounted) return;
        if (assignResult['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                assignResult['message']?.toString() ??
                    'Pond saved but hardware binding failed — reopen the pond and retry.',
              ),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          Navigator.pop(context, true);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.pond != null
                ? 'Pond updated successfully'
                : 'Pond created successfully',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      // Home/Schedule must refresh its pond list when this returns true.
      Navigator.pop(context, true);
      return;
    }

    String errorMsg = result['message'] ?? 'Failed to save pond';
    if (result['errors'] is Map) {
      final errors = result['errors'] as Map;
      if (errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          errorMsg = firstError.first.toString();
        } else {
          errorMsg = firstError.toString();
        }
      }
    } else if (result['error'] != null) {
      errorMsg = result['error'].toString();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $errorMsg'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 600 ? 48.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.createNewSchedule,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1544552866-d3ed42536cfd?w=800',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'OPERATIONAL MODE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Configure automated feeding',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        _sectionTitle(context, 'Pond Selection'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _siteLocationController,
                          decoration: _inputDecoration(
                            label: 'Site Location',
                            hint: 'Enter site location',
                            icon: Icons.location_on,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter site location'
                              : null,
                        ),

                        const SizedBox(height: 24),
                        _sectionTitle(context, 'Batch Info'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _speciesController,
                                decoration: _inputDecoration(
                                  label: 'Current Species',
                                  hint: 'e.g., Tilapia',
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _estCountController,
                                decoration: _inputDecoration(
                                  label: 'Est. Count',
                                  hint: '0',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _startDateController,
                          readOnly: true,
                          onTap: _selectStartDate,
                          decoration: _inputDecoration(
                            label: 'Start Date',
                            hint: 'mm/dd/yyyy',
                            icon: Icons.calendar_today,
                            suffix: IconButton(
                              onPressed: _selectStartDate,
                              icon: const Icon(Icons.calendar_month),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please select start date'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _endDateController,
                          readOnly: true,
                          onTap: _selectEndDate,
                          decoration: _inputDecoration(
                            label: 'End Date',
                            hint: 'mm/dd/yyyy',
                            icon: Icons.calendar_today,
                            suffix: IconButton(
                              onPressed: _selectEndDate,
                              icon: const Icon(Icons.calendar_month),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select end date';
                            }
                            if (_endDate != null &&
                                _startDate != null &&
                                _endDate!.isBefore(_startDate!)) {
                              return 'End date must be after start date';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),
                        _sectionTitle(context, 'Feeding Schedule'),
                        const SizedBox(height: 12),

                        if (_feedingSchedules.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: const Text(
                              'No feeding times added yet. Tap + Add Time to create a feeding time and amount.',
                              style: TextStyle(height: 1.4),
                            ),
                          )
                        else
                          Column(
                            children: [
                              for (
                                int index = 0;
                                index < _feedingSchedules.length;
                                index++
                              )
                                _feedingScheduleCard(index),
                            ],
                          ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showAddFeedingDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Time'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        _sectionTitle(context, 'Hardware ID'),
                        const SizedBox(height: 16),
                        // Registered-device picker: sends the device UUID as
                        // `deviceId` so the backend binds devices.pond_id and
                        // the ESP32 actually polls this pond's schedules.
                        // A manually typed label is registered on save.
                        HardwareIdActionButton(
                          hardwareId: _selectedDeviceCode,
                          deviceId: _selectedDeviceId,
                          availableDevices: _availableDevices,
                          loadingDevices: _loadingDevices,
                          onRefreshDevices: _refreshAvailableDevices,
                          onCreateDevice: (code) => ApiService.instance
                              .createDevice(deviceCode: code),
                          onSelected: _applyHardwareSelection,
                        ),

                        const SizedBox(height: 32),

                        _sectionTitle(context, 'Recommended Feeding'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calculate_outlined,
                                    color: AppTheme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _recommendedSummary(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _applyRecommended,
                                  icon: Icon(
                                    _showRecommended
                                        ? Icons.check_circle
                                        : Icons.auto_fix_high,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _showRecommended
                                        ? 'Apply recommended amounts'
                                        : 'Calculate recommendation',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_showRecommended)
                                SizedBox(
                                  child: Text(
                                  'Tap again to refresh amounts with the latest '
                                  'estimated count and average fish weight.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.pond != null ? 'Save Pond' : 'Create Pond',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.textSecondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Precision Feeding Tip',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'TDS (water conductivity) and pH affect feed uptake — ensure TDS and pH are within safe ranges before dispensing. Sensors will auto-verify conditions before dispensing.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        if (_hasAlert)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.warningColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notification_important,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _alertTitle.isNotEmpty
                                            ? _alertTitle
                                            : 'Sensor Alert',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.warningColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _alertMessage.isNotEmpty
                                            ? _alertMessage
                                            : 'One or more sensor readings (feed stock, pH, TDS, temperature) indicate attention is needed.',
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
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppTheme.primaryColor),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _feedingScheduleCard(int index) {
    final schedule = _feedingSchedules[index];
    final time = schedule['time'] as String;
    final amount = (schedule['amount'] as num).toDouble();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.access_time, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${amount.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _removeFeedingSchedule(index),
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }
}
