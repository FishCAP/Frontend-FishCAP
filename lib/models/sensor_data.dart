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

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'] ?? '',
      deviceId: json['deviceId'] ?? json['device_id'] ?? '',
      temperature: (json['temperature'] as num?)?.toDouble(),
      ph: (json['ph'] as num?)?.toDouble(),
      dissolvedOxygen: ((json['dissolvedOxygen'] ?? json['dissolved_oxygen']) as num?)?.toDouble(),
      createdAt: (json['createdAt'] ?? json['created_at']) != null
          ? DateTime.tryParse((json['createdAt'] ?? json['created_at']).toString())
          : null,
    );
  }
}
