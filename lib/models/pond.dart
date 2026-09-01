/// One feeding schedule row as returned by the backend's pond list/detail
/// payloads: `{ id, time, title, amount, status }`.
class FeedSchedule {
  final String id;
  final String time;
  final String title;
  final double? amount;
  final String status;

  const FeedSchedule({
    this.id = '',
    required this.time,
    this.title = '',
    this.amount,
    this.status = 'Scheduled',
  });

  factory FeedSchedule.fromJson(Map<String, dynamic> json) {
    return FeedSchedule(
      id: json['id']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      amount: _parsePondDecimal(json['amount']),
      status: json['status']?.toString() ?? 'Scheduled',
    );
  }
}

/// Safely parses a value that may arrive as [num], [String] or null into a
/// [double]. Postgres/MySQL DECIMAL columns are serialized as strings by the
/// backend (e.g. "8.00"), so calling `.toDouble()` directly would throw.
double? _parsePondDecimal(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

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
  final List<FeedSchedule> feedSchedules;

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
    this.feedSchedules = const [],
  });

  /// Whether this pond has been marked as done/completed.
  ///
  /// Done ponds are shown in the History screen; active ponds are shown in
  /// the Schedule screen. The status string is normalised (lower-cased) so
  /// that any common "done" spelling (`done` / `completed` / `finished`) is
  /// treated the same way regardless of casing.
  bool get isDone {
    final normalized = status.toLowerCase();
    return normalized == 'done' ||
        normalized == 'completed' ||
        normalized == 'finished';
  }

  /// Convenience toggle target used when flipping a pond between the
  /// Schedule (active) and History (done) screens.
  static const String doneStatus = 'done';
  static const String activeStatus = 'active';

  factory Pond.fromJson(Map<String, dynamic> json) {
    return Pond(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['pondName'] ?? 'Unknown Pond',
      species: json['species'] ?? json['fishType'] ?? 'Unknown Species',
      location: json['location'],
      estimatedCount: _parseInt(json['estimatedCount'] ?? json['fishCount']),
      startDate: json['startDate'],
      endDate: json['endDate'],
      ph: json['ph']?.toString(),
      oxygen: json['oxygen']?.toString(),
      temperature: json['temperature']?.toString() ?? '--',
      status: json['status'] ?? 'Active',
      statusColor: json['statusColor'] ?? '#4CAF50',
      hasAlert: json['hasAlert'] ?? false,
      feedingTimes: json['feedingTimes'] is List
          ? List<String>.from(json['feedingTimes'] as List)
          : null,
      amount: _parseDouble(json['amount']),
      hardwareId: json['hardwareId'],
      feedSchedules: json['feedSchedules'] is List
          ? (json['feedSchedules'] as List)
                .whereType<Map>()
                .map((e) => FeedSchedule.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }

  /// Safely parses a value that may arrive as [int], [double], [String] or
  /// null into an [int]. Prevents `.toInt()` crashes when the API returns
  /// numbers as strings.
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// Safely parses a value that may arrive as [num], [String] or null into a
  /// [double]. MySQL DECIMAL columns are serialized as strings by the backend
  /// (e.g. "8.00"), so calling `.toDouble()` directly on the JSON value
  /// throws a NoSuchMethodError and would skip the whole pond.
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
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
      'feedSchedules': feedSchedules
          .map(
            (s) => {
              'id': s.id,
              'time': s.time,
              'title': s.title,
              'amount': s.amount,
              'status': s.status,
            },
          )
          .toList(),
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
    List<FeedSchedule>? feedSchedules,
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
      feedSchedules: feedSchedules ?? this.feedSchedules,
    );
  }
}
