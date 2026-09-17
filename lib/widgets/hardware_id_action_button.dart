import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Result of a hardware-ID selection made from [HardwareIdDialog].
///
/// `deviceId` is the UUID of a registered device (used for the new-pond
/// `deviceId` payload path); `hardwareId` is the human-readable hardware code
/// (e.g. `FEEDER-09-AX`) stored as `hardwareId` for existing ponds.
class HardwareIdSelection {
  final String? deviceId;
  final String? hardwareId;

  const HardwareIdSelection({this.deviceId, this.hardwareId});
}

/// A tappable card that represents the pond's hardware-ID assignment.
///
/// It displays the currently assigned hardware id (or a prompt to assign one)
/// and opens [HardwareIdDialog] when tapped so the user can either **create**
/// a new hardware device, pick an existing available device, or **put** a
/// hardware id manually.
class HardwareIdActionButton extends StatelessWidget {
  /// Currently assigned hardware id, for display.
  final String? hardwareId;

  /// UUID of a currently assigned device, for display/pre-selection.
  final String? deviceId;

  /// Devices returned by `GET /api/devices/available`.
  final List<Map<String, dynamic>> availableDevices;

  /// Whether the available-devices list is still loading.
  final bool loadingDevices;

  /// Called when the user confirms a selection.
  final ValueChanged<HardwareIdSelection> onSelected;

  /// Called to reload the list of available devices.
  final Future<void> Function() onRefreshDevices;

  /// Called with a device code to register a brand-new device.
  final Future<Map<String, dynamic>> Function(String deviceCode)?
  onCreateDevice;

  const HardwareIdActionButton({
    super.key,
    this.hardwareId,
    this.deviceId,
    this.availableDevices = const [],
    this.loadingDevices = false,
    required this.onSelected,
    required this.onRefreshDevices,
    this.onCreateDevice,
  });

  @override
  Widget build(BuildContext context) {
    final assigned = (hardwareId != null && hardwareId!.trim().isNotEmpty)
        ? hardwareId!.trim()
        : null;

    return InkWell(
      onTap: () => _openDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          border: Border.all(
            color: assigned != null
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.memory,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hardware ID',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  assigned != null
                      ? Text(
                          assigned,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        )
                      : Text(
                          'Tap to create or assign a hardware ID',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.cardColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: HardwareIdDialog(
          hardwareId: hardwareId,
          deviceId: deviceId,
          availableDevices: availableDevices,
          loadingDevices: loadingDevices,
          onRefreshDevices: onRefreshDevices,
          onCreateDevice: onCreateDevice,
          onSelected: onSelected,
        ),
      ),
    );
  }
}

/// Dialog that lets the user **create** (or pick) a hardware device, or **put**
/// a hardware id manually, then confirm the selection.
class HardwareIdDialog extends StatefulWidget {
  final String? hardwareId;
  final String? deviceId;
  final List<Map<String, dynamic>> availableDevices;
  final bool loadingDevices;
  final Future<void> Function() onRefreshDevices;
  final Future<Map<String, dynamic>> Function(String deviceCode)?
  onCreateDevice;
  final ValueChanged<HardwareIdSelection> onSelected;

  const HardwareIdDialog({
    super.key,
    this.hardwareId,
    this.deviceId,
    this.availableDevices = const [],
    this.loadingDevices = false,
    required this.onRefreshDevices,
    this.onCreateDevice,
    required this.onSelected,
  });

  @override
  State<HardwareIdDialog> createState() => _HardwareIdDialogState();
}

class _HardwareIdDialogState extends State<HardwareIdDialog> {
  final _manualController = TextEditingController();

  /// The device map picked from the registry (if any).
  Map<String, dynamic>? _selectedDevice;

  /// Tracks the in-progress "generate new device" call.
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill manual entry with the current id so it can be edited.
    _manualController.text = widget.hardwareId ?? '';
  }

  /// Builds a plausible, unique-ish device code.
  String _generateDeviceCode() {
    final stamp = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'FEEDER-${stamp.toString().padLeft(4, '0')}-AX';
  }

  Future<void> _createNewDevice() async {
    final onCreate = widget.onCreateDevice;
    if (onCreate == null) return;

    final code = _generateDeviceCode();
    setState(() => _creating = true);
    try {
      final result = await onCreate(code);
      if (!mounted) return;
      if (result['success'] == true && result['data'] is Map) {
        final data = result['data'] as Map;
        // Auto-select the freshly created device.
        setState(() {
          _selectedDevice = {
            'id': data['id']?.toString(),
            'deviceCode': data['deviceCode']?.toString() ?? code,
            'deviceName': data['deviceName']?.toString(),
          };
        });
      } else if (mounted && result['message'] != null) {
        _showSnackBar('Failed to create device: ${result['message']}');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _selectDevice(Map<String, dynamic> device) {
    setState(() {
      _selectedDevice = device;
      // Clear manual entry when a device is chosen explicitly.
      _manualController.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _isConfirmEnabled {
    if (_selectedDevice != null) return true;
    return _manualController.text.trim().isNotEmpty;
  }

  void _confirm() {
    final manual = _manualController.text.trim();
    HardwareIdSelection selection;
    if (_selectedDevice != null) {
      final code = _selectedDevice!['deviceCode']?.toString() ?? manual;
      final id = _selectedDevice!['id']?.toString();
      selection = HardwareIdSelection(
        deviceId: id,
        hardwareId: code.isNotEmpty ? code : manual,
      );
    } else {
      selection = HardwareIdSelection(hardwareId: manual);
    }

    final hasValue =
        selection.hardwareId != null && selection.hardwareId!.isNotEmpty;
    if (!hasValue) return;

    widget.onSelected(selection);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ---- Header ----
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.memory,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Assign Hardware ID',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---- Pick an existing device / generate a new one ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Devices',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (widget.onCreateDevice != null)
                      TextButton.icon(
                        onPressed: _creating ? null : _createNewDevice,
                        icon: _creating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add, size: 18),
                        label: const Text('Generate new ID'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.loadingDevices)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (widget.availableDevices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No registered devices. Enter an ID manually below.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.availableDevices.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final device = widget.availableDevices[index];
                      final code =
                          device['deviceCode']?.toString() ?? 'Unknown';
                      final name = device['deviceName']?.toString();
                      final deviceId = device['id']?.toString();
                      final bool selected = _selectedDevice?['id']
                              ?.toString() ==
                          deviceId &&
                          deviceId != null;

                      return ListTile(
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                        title: Text(
                          code,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected
                                ? AppTheme.textPrimary
                                : null,
                          ),
                        ),
                        subtitle: (name != null && name.isNotEmpty)
                            ? Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              )
                            : null,
                        onTap: () => _selectDevice(device),
                      );
                    },
                  ),

                if (!widget.loadingDevices)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: widget.onRefreshDevices,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),
                const Divider(thickness: 1),
                const SizedBox(height: 12),

                // ---- Or enter a hardware id manually ----
                Text(
                  'Or enter a hardware ID manually',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _manualController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'e.g. FEEDER-09-AX',
                    prefixIcon: const Icon(
                      Icons.memory,
                      color: AppTheme.primaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // ---- Actions ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.textSecondary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isConfirmEnabled ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.done_rounded, size: 20),
                  label: const Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
