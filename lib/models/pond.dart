class Pond {
  final String id;
  final String name;
  final String species;
  final String? location;
  final int? estimatedCount;
  final String? startDate;
  final String? endDate;
  final String? ph;
  final String? oxygen;
  final String temperature;
  final String status;
  final String statusColor;
  final bool hasAlert;
  final List<String>? feedingTimes;
  final double? amount;
  final String? hardwareId;

  Pond({
    required this.id,
    required this.name,
    required this.species,
    this.location,
    this.estimatedCount,
    this.startDate,
    this.endDate,
    this.ph,
    this.oxygen,
    required this.temperature,
    required this.status,
    required this.statusColor,
    this.hasAlert = false,
    this.feedingTimes,
    this.amount,
    this.hardwareId,
  });

  factory Pond.fromJson(Map<String, dynamic> json) {
    return Pond(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['pondName'] ?? 'Unknown Pond',
      species: json['species'] ?? json['fishType'] ?? 'Unknown Species',
      location: json['location'],
      estimatedCount: (json['estimatedCount'] ?? json['fishCount'])?.toInt(),
      startDate: json['startDate'],
      endDate: json['endDate'],
      ph: json['ph']?.toString(),
      oxygen: json['oxygen']?.toString(),
      temperature: json['temperature']?.toString() ?? '--',
      status: json['status'] ?? 'Active',
      statusColor: json['statusColor'] ?? '#4CAF50',
      hasAlert: json['hasAlert'] ?? false,
      feedingTimes: json['feedingTimes'] != null
          ? List<String>.from(json['feedingTimes'])
          : null,
      amount: json['amount']?.toDouble(),
      hardwareId: json['hardwareId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'location': location,
      'estimatedCount': estimatedCount,
      'startDate': startDate,
      'endDate': endDate,
      'ph': ph,
      'oxygen': oxygen,
      'temperature': temperature,
      'status': status,
      'statusColor': statusColor,
      'hasAlert': hasAlert,
      'feedingTimes': feedingTimes,
      'amount': amount,
      'hardwareId': hardwareId,
    };
  }

  Pond copyWith({
    String? id,
    String? name,
    String? species,
    String? location,
    int? estimatedCount,
    String? startDate,
    String? endDate,
    String? ph,
    String? oxygen,
    String? temperature,
    String? status,
    String? statusColor,
    bool? hasAlert,
    List<String>? feedingTimes,
    double? amount,
    String? hardwareId,
  }) {
    return Pond(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      location: location ?? this.location,
      estimatedCount: estimatedCount ?? this.estimatedCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ph: ph ?? this.ph,
      oxygen: oxygen ?? this.oxygen,
      temperature: temperature ?? this.temperature,
      status: status ?? this.status,
      statusColor: statusColor ?? this.statusColor,
      hasAlert: hasAlert ?? this.hasAlert,
      feedingTimes: feedingTimes ?? this.feedingTimes,
      amount: amount ?? this.amount,
      hardwareId: hardwareId ?? this.hardwareId,
    );
  }
}
