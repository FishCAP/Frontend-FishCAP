class SensorData {
  final String id;
  final String deviceId;
  final double? temperature;
  final double? ph;
  final double? dissolvedOxygen;
  final DateTime? createdAt;

  SensorData({
    required this.id,
    required this.deviceId,
    this.temperature,
    this.ph,
    this.dissolvedOxygen,
    this.createdAt,
  });

  /// Safely parses a value that may arrive as [num], [String] or null into a
  /// [double]. MySQL DECIMAL columns are serialized as strings by the backend
  /// (e.g. "8.00"), so a raw `as num?` cast would throw a TypeError.
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'] ?? '',
      deviceId: json['deviceId'] ?? json['device_id'] ?? '',
      temperature: _parseDouble(json['temperature']),
      ph: _parseDouble(json['ph']),
      dissolvedOxygen: _parseDouble(
        json['dissolvedOxygen'] ?? json['dissolved_oxygen'],
      ),
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString())
          : null,
    );
  }
}
