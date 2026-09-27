import 'sleep_data.dart';
import 'sleep_recommendation.dart';

class WeeklySleepItem {
  final String date;
  final double? sleepHours;
  final int? sleepScore;
  final String? bedtime;
  final String? wakeTime;

  WeeklySleepItem({
    required this.date,
    this.sleepHours,
    this.sleepScore,
    this.bedtime,
    this.wakeTime,
  });

  factory WeeklySleepItem.fromJson(Map<String, dynamic> json) {
    return WeeklySleepItem(
      date: json['date'] ?? '',
      sleepHours: json['sleepHours'] != null ? (json['sleepHours'] as num).toDouble() : null,
      sleepScore: json['sleepScore'] != null ? (json['sleepScore'] as num).toInt() : null,
      bedtime: json['bedtime'],
      wakeTime: json['wakeTime'] ?? json['wake_time'],
    );
  }
}


class DashboardData {
  final String date;
  final int? sleepScore;
  final double? sleepHours;
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

  DashboardData({
    required this.date,
    this.sleepScore,
    this.sleepHours,
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

    return DashboardData(
      date: json['date'] ?? '',
      sleepScore: json['sleepScore'] != null ? (json['sleepScore'] as num).toInt() : null,
      sleepHours: json['sleepHours'] != null ? (json['sleepHours'] as num).toDouble() : null,
      restingHR: json['restingHR'] != null ? (json['restingHR'] as num).toInt() : null,
      hrv: json['hrv'] != null ? (json['hrv'] as num).toInt() : null,
      vo2max: json['vo2max'] != null ? (json['vo2max'] as num).toDouble() : null,
      bodyBatteryHigh: json['bodyBatteryHigh'] != null ? (json['bodyBatteryHigh'] as num).toInt() : null,
      bodyBatteryLow: json['bodyBatteryLow'] != null ? (json['bodyBatteryLow'] as num).toInt() : null,
      steps: json['steps'] != null ? (json['steps'] as num).toInt() : null,
      deepSleepMins: json['deepSleepMins'] ?? 0,
      lightSleepMins: json['lightSleepMins'] ?? 0,
      remSleepMins: json['remSleepMins'] ?? 0,
      awakeMins: json['awakeMins'] ?? 0,
      bedtime: json['bedtime'],
      wakeTime: json['wakeTime'],
      morningNote: json['morningNote'],
      morningVerdict: json['morningVerdict'],
      sleepEngineRecommendation: recJson != null ? SleepRecommendation.fromJson(recJson) : null,
      weeklyChart: weeklyList,
      sleepStages: stagesList,
    );
  }
}
