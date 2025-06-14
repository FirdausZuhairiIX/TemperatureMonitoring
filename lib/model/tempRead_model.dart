class TemperatureReading {
  final String readingId;
  final double temperature;
  final DateTime time;
  final String toddlerId;

  TemperatureReading({
    required this.readingId,
    required this.temperature,
    required this.time,
    required this.toddlerId,
  });

  factory TemperatureReading.fromMap(Map<String, dynamic> map, String readingId) {
    return TemperatureReading(
      readingId: readingId,
      temperature: (map['temp_read'] as num).toDouble(),
      time: DateTime.parse(map['temp_time']),
      toddlerId: map['toddler_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temp_read': temperature,
      'temp_time': time.toIso8601String(),
      'toddler_id': toddlerId,
    };
  }
}