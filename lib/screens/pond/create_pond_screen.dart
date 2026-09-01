import 'package:flutter/material.dart';
import 'package:fishcap_app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../models/pond.dart';
import '../../services/api_service.dart';
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

  // Each feeding schedule has its own time and amount.
  final List<Map<String, dynamic>> _feedingSchedules = [];

  @override
  void initState() {
    super.initState();
    if (widget.pond != null) {
      _loadPondData(widget.pond!);
    }
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

    if (_hardwareIdController.text.trim().isNotEmpty) {
      pondData['hardwareId'] = _hardwareIdController.text.trim();
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
                        _sectionTitle(context, 'Hardware'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _hardwareIdController,
                          decoration: _inputDecoration(
                            label: 'Hardware Product ID',
                            hint: 'e.g., FEEDER-09-AX',
                            icon: Icons.memory,
                            suffix: const Icon(
                              Icons.verified,
                              color: AppTheme.successColor,
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Please enter hardware ID'
                              : null,
                        ),

                        const SizedBox(height: 32),
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
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        widget.pond != null
                                            ? Icons.update
                                            : Icons.save,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.pond != null
                                            ? 'Update Pond'
                                            : 'Save Schedule',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
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
                                      'Optimal feeding occurs when water oxygen levels are above 5.0 mg/L. Sensors will auto-verify conditions before dispensing.',
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
