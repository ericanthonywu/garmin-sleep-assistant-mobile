class SleepStageInterval {
  final String stage; // 'deep', 'light', 'rem', 'awake'
  final DateTime startTime;
  final DateTime endTime;
  final int durationSecs;

  SleepStageInterval({
    required this.stage,
    required this.startTime,
    required this.endTime,
    required this.durationSecs,
  });

  factory SleepStageInterval.fromJson(Map<String, dynamic> json) {
    return SleepStageInterval(
      stage: json['stage'] ?? json['stage_name'] ?? 'light',
      startTime: DateTime.tryParse(json['start_time'] ?? json['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] ?? json['endTime'] ?? '') ?? DateTime.now(),
      durationSecs: json['duration_secs'] ?? json['durationSecs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'stage': stage,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'durationSecs': durationSecs,
  };
}

class OvernightHeartRate {
  final DateTime timestamp;
  final int bpm;

  OvernightHeartRate({
    required this.timestamp,
    required this.bpm,
  });

  factory OvernightHeartRate.fromJson(Map<String, dynamic> json) {
    return OvernightHeartRate(
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['t'] ?? '') ?? DateTime.now(),
      bpm: json['bpm'] ?? 0,
    );
  }
}
