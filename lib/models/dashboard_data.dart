import '../utils/time_formatter.dart';
import 'sleep_data.dart';
import 'sleep_recommendation.dart';

class MagnesiumLog {
  final bool taken;
  final String? takenAt;
  final String? dosage;
  final String? notes;

  MagnesiumLog({
    required this.taken,
    this.takenAt,
    this.dosage,
    this.notes,
  });

  factory MagnesiumLog.fromJson(Map<String, dynamic> json) {
    return MagnesiumLog(
      taken: json['taken'] == true,
      takenAt: json['takenAt'] ?? json['taken_at'],
      dosage: json['dosage'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'taken': taken,
    'takenAt': takenAt,
    'dosage': dosage,
    'notes': notes,
  };
}

class MagnesiumWeeklyStats {
  final int takenDays;
  final int totalDays;
  final int adherenceRate;

  MagnesiumWeeklyStats({
    required this.takenDays,
    required this.totalDays,
    required this.adherenceRate,
  });

  factory MagnesiumWeeklyStats.fromJson(Map<String, dynamic> json) {
    return MagnesiumWeeklyStats(
      takenDays: (json['takenDays'] as num?)?.toInt() ?? 0,
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 7,
      adherenceRate: (json['adherenceRate'] as num?)?.toInt() ?? 0,
    );
  }
}

class WeeklySleepItem {
  final String date;
  final double? sleepHours;
  final int? sleepSecs;
  final int? sleepScore;
  final String? bedtime;
  final String? wakeTime;
  final bool magnesiumTaken;

  WeeklySleepItem({
    required this.date,
    this.sleepHours,
    this.sleepSecs,
    this.sleepScore,
    this.bedtime,
    this.wakeTime,
    this.magnesiumTaken = false,
  });

  String get sleepDurationLabel =>
      TimeFormatter.formatDurationSecs(sleepSecs ?? (sleepHours != null ? sleepHours! * 3600 : null));

  factory WeeklySleepItem.fromJson(Map<String, dynamic> json) {
    return WeeklySleepItem(
      date: json['date'] ?? '',
      sleepHours: json['sleepHours'] != null ? (json['sleepHours'] as num).toDouble() : null,
      sleepSecs: json['sleepSecs'] != null ? (json['sleepSecs'] as num).round() : null,
      sleepScore: json['sleepScore'] != null ? (json['sleepScore'] as num).toInt() : null,
      bedtime: json['bedtime'],
      wakeTime: json['wakeTime'] ?? json['wake_time'],
      magnesiumTaken: json['magnesiumTaken'] == true,
    );
  }
}


class DashboardData {
  final String date;
  final int? sleepScore;
  final double? sleepHours;
  final int? sleepSecs;
  final int? restingHR;
  final int? hrv;
  final double? vo2max;
  final int? bodyBatteryHigh;
  final int? bodyBatteryLow;
  final int? steps;
  final int deepSleepMins;
  final int lightSleepMins;
  final int remSleepMins;
  final int awakeMins;
  final String? bedtime;
  final String? wakeTime;
  final String? morningNote;
  final String? morningVerdict; // 'good', 'okay', 'bad', 'terrible'
  final SleepRecommendation? sleepEngineRecommendation;
  final List<WeeklySleepItem> weeklyChart;
  final List<SleepStageInterval> sleepStages;
  final MagnesiumLog? magnesium;
  final MagnesiumWeeklyStats? magnesiumWeeklyStats;

  DashboardData({
    required this.date,
    this.sleepScore,
    this.sleepHours,
    this.sleepSecs,
    this.restingHR,
    this.hrv,
    this.vo2max,
    this.bodyBatteryHigh,
    this.bodyBatteryLow,
    this.steps,
    required this.deepSleepMins,
    required this.lightSleepMins,
    required this.remSleepMins,
    required this.awakeMins,
    this.bedtime,
    this.wakeTime,
    this.morningNote,
    this.morningVerdict,
    this.sleepEngineRecommendation,
    required this.weeklyChart,
    required this.sleepStages,
    this.magnesium,
    this.magnesiumWeeklyStats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final weeklyList = (json['weeklyChart'] as List<dynamic>?)
            ?.map((e) => WeeklySleepItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final stagesList = (json['sleepStages'] as List<dynamic>?)
            ?.map((e) => SleepStageInterval.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final recJson = json['sleepEngineRecommendation'];
    final magJson = json['magnesium'];
    final magStatsJson = json['magnesiumWeeklyStats'];

    return DashboardData(
      date: json['date'] ?? '',
      sleepScore: json['sleepScore'] != null ? (json['sleepScore'] as num).toInt() : null,
      sleepHours: json['sleepHours'] != null ? (json['sleepHours'] as num).toDouble() : null,
      sleepSecs: json['sleepSecs'] != null ? (json['sleepSecs'] as num).round() : null,
      restingHR: json['restingHR'] != null ? (json['restingHR'] as num).toInt() : null,
      hrv: json['hrv'] != null ? (json['hrv'] as num).toInt() : null,
      vo2max: json['vo2max'] != null ? (json['vo2max'] as num).toDouble() : null,
      bodyBatteryHigh: json['bodyBatteryHigh'] != null ? (json['bodyBatteryHigh'] as num).toInt() : null,
      bodyBatteryLow: json['bodyBatteryLow'] != null ? (json['bodyBatteryLow'] as num).toInt() : null,
      steps: json['steps'] != null ? (json['steps'] as num).toInt() : null,
      deepSleepMins: (json['deepSleepMins'] as num?)?.round() ?? 0,
      lightSleepMins: (json['lightSleepMins'] as num?)?.round() ?? 0,
      remSleepMins: (json['remSleepMins'] as num?)?.round() ?? 0,
      awakeMins: (json['awakeMins'] as num?)?.round() ?? 0,
      bedtime: json['bedtime'],
      wakeTime: json['wakeTime'],
      morningNote: json['morningNote'],
      morningVerdict: json['morningVerdict'],
      sleepEngineRecommendation: recJson != null ? SleepRecommendation.fromJson(recJson) : null,
      weeklyChart: weeklyList,
      sleepStages: stagesList,
      magnesium: magJson != null ? MagnesiumLog.fromJson(magJson as Map<String, dynamic>) : null,
      magnesiumWeeklyStats: magStatsJson != null
          ? MagnesiumWeeklyStats.fromJson(magStatsJson as Map<String, dynamic>)
          : null,
    );
  }
}
