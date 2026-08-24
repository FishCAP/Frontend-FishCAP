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
  final _feedingTimeController = TextEditingController();
  final _amountController = TextEditingController();
  final _hardwareIdController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _feedingTime;
  final List<String> _feedingTimes = [];
  bool _isLoading = false;

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
    // If dates are stored in ISO, format them for display
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
    _amountController.text = pond.amount?.toString() ?? '';
    _hardwareIdController.text = pond.hardwareId ?? '';
    if (pond.feedingTimes != null && pond.feedingTimes!.isNotEmpty) {
      _feedingTimes.addAll(pond.feedingTimes!);
    }
  }

  @override
  void dispose() {
    _siteLocationController.dispose();
    _speciesController.dispose();
    _estCountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _feedingTimeController.dispose();
    _amountController.dispose();
    _hardwareIdController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
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

  Future<void> _selectFeedingTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _feedingTime = picked;
        _feedingTimeController.text = picked.format(
          context,
        ); // Display as user-friendly
      });
    }
  }

  void _addFeedingTime() {
    if (_feedingTime != null && _feedingTimeController.text.isNotEmpty) {
      // Convert to 24-hour HH:mm for the server
      final serverTime =
          '${_feedingTime!.hour.toString().padLeft(2, '0')}:${_feedingTime!.minute.toString().padLeft(2, '0')}';
      setState(() {
        _feedingTimes.add(serverTime); // e.g. "13:09"
        _feedingTimeController.clear();
        _feedingTime = null;
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final apiService = ApiService.instance;

    // Build payload with proper types
    final Map<String, dynamic> pondData = {};

    // Required fields
    pondData['name'] = _siteLocationController.text.trim();
    pondData['location'] = _siteLocationController.text.trim();
    pondData['species'] = _speciesController.text.trim();

    // Numeric fields – send as numbers
    final estCount = int.tryParse(_estCountController.text.trim());
    if (estCount != null) pondData['estimatedCount'] = estCount;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount != null) pondData['amount'] = amount;

    // Dates – send as ISO‑8601 (YYYY-MM-DD)
    if (_startDate != null) {
      pondData['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      pondData['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
    }

    // Feeding times – already in HH:mm format
    if (_feedingTimes.isNotEmpty) {
      pondData['feedingTimes'] = _feedingTimes;
    }

    // Hardware ID – send as string
    if (_hardwareIdController.text.trim().isNotEmpty) {
      pondData['hardwareId'] = _hardwareIdController.text.trim();
    }

    // 🔥 IMPORTANT: Do NOT send status, statusColor, hasAlert, temperature
    // These are server‑managed or read‑only.

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

    setState(() {
      _isLoading = false;
    });

    // 🔥 Better error extraction
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
      Navigator.pop(context, true);
    } else {
      // Try to extract detailed validation errors
      String errorMsg = result['message'] ?? 'Failed to save pond';
      if (result['errors'] != null && result['errors'] is Map) {
        final errors = result['errors'] as Map;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          errorMsg = firstError.first.toString();
        }
      } else if (result['error'] != null) {
        errorMsg = result['error'].toString();
      }
      // If the server returns a string in a different key, add it here

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMsg'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // ... (rest of the build method remains exactly as previously provided)
  // I'll include it for completeness below.
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
                        // Header
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
                            Text(
                              l10n.createNewSchedule,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Header Image
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
                                    child: Text(
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

                        // Pond Selection Section
                        Text(
                          'Pond Selection',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Site Location
                        TextFormField(
                          controller: _siteLocationController,
                          decoration: InputDecoration(
                            labelText: 'Site Location',
                            hintText: 'Enter site location',
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: AppTheme.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter site location';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Batch Info Section
                        Text(
                          'Batch Info',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            // Current Species
                            Expanded(
                              child: TextFormField(
                                controller: _speciesController,
                                decoration: InputDecoration(
                                  labelText: 'Current Species',
                                  hintText: 'e.g., Tilapia',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Est. Count
                            Expanded(
                              child: TextFormField(
                                controller: _estCountController,
                                decoration: InputDecoration(
                                  labelText: 'Est. Count',
                                  hintText: '0',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Start Date
                        TextFormField(
                          controller: _startDateController,
                          decoration: InputDecoration(
                            labelText: 'Start Date',
                            hintText: 'mm/dd/yyyy',
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: IconButton(
                              onPressed: _selectStartDate,
                              icon: const Icon(
                                Icons.calendar_month,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          readOnly: true,
                          onTap: _selectStartDate,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select start date';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // End Date
                        TextFormField(
                          controller: _endDateController,
                          decoration: InputDecoration(
                            labelText: 'End Date',
                            hintText: 'mm/dd/yyyy',
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: IconButton(
                              onPressed: _selectEndDate,
                              icon: const Icon(
                                Icons.calendar_month,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          readOnly: true,
                          onTap: _selectEndDate,
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

                        // Schedule Settings Section
                        Text(
                          'Schedule Settings',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Feeding Time
                        TextFormField(
                          controller: _feedingTimeController,
                          decoration: InputDecoration(
                            labelText: 'Feeding Time',
                            hintText: 'Select time',
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: IconButton(
                              onPressed: _selectFeedingTime,
                              icon: const Icon(
                                Icons.schedule,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          readOnly: true,
                          onTap: _selectFeedingTime,
                        ),

                        const SizedBox(height: 12),

                        // Add Time Button
                        OutlinedButton.icon(
                          onPressed: _addFeedingTime,
                          icon: const Icon(
                            Icons.add,
                            color: AppTheme.primaryColor,
                          ),
                          label: const Text(
                            'Add Time',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppTheme.primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Amount (kg)
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount (kg)',
                            hintText: '0.00',
                            suffixText: 'kg',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter amount';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Hardware Section
                        Text(
                          'Hardware',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),

                        const SizedBox(height: 16),

                        // Hardware Product ID
                        TextFormField(
                          controller: _hardwareIdController,
                          decoration: InputDecoration(
                            labelText: 'Hardware Product ID',
                            hintText: 'e.g., FEEDER-09-AX',
                            prefixIcon: const Icon(
                              Icons.memory,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: const Icon(
                              Icons.verified,
                              color: AppTheme.successColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter hardware ID';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Save Button
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

                        // Cancel Button
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
                            child: Text(
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

                        // Info Tip
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
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
                                    const SizedBox(height: 4),
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

                        const SizedBox(
                          height: 100,
                        ), // Space for bottom navigation
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
}
