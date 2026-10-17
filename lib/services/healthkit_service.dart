import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthKitService {
  final Health _health = Health();

  static const List<HealthDataType> _sleepTypes = [
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  static const List<HealthDataType> _biometricTypes = [
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.WORKOUT,
  ];

  /// Request permissions for all health types.
  Future<bool> requestPermissions() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final types = [..._sleepTypes, ..._biometricTypes];
      final requested = await _health.requestAuthorization(types);
      return requested;
    } catch (e) {
      debugPrint('[HealthKitService] Authorization error: $e');
      return false;
    }
  }

  /// Fetch sleep intervals for the night ending on [date], sorted by start time.
  /// A night owns every segment starting between noon yesterday and noon today, so
  /// consecutive days never share a segment. Segments come from a single source
  /// (the one with the most sleep) because Garmin and Apple Watch both write here.
  Future<List<Map<String, dynamic>>> fetchSleepStages(DateTime date) async {
    if (!Platform.isIOS) return [];

    try {
      final nightStart = DateTime(date.year, date.month, date.day - 1, 12, 0);
      final nightEnd = DateTime(date.year, date.month, date.day, 12, 0);

      final points = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_ASLEEP,
        ],
        startTime: nightStart,
        endTime: nightEnd.add(const Duration(hours: 6)),
      );

      final bySource = <String, List<HealthDataPoint>>{};
      for (final p in points) {
        if (p.dateFrom.isBefore(nightStart) || !p.dateFrom.isBefore(nightEnd)) continue;
        if (!p.dateTo.isAfter(p.dateFrom) || _mapTypeToStage(p.type) == null) continue;
        bySource.putIfAbsent(p.sourceId, () => []).add(p);
      }
      if (bySource.isEmpty) return [];

      int asleepSecs(List<HealthDataPoint> pts) => pts
          .where((p) => p.type != HealthDataType.SLEEP_AWAKE)
          .fold(0, (sum, p) => sum + p.dateTo.difference(p.dateFrom).inSeconds);
      var chosen = bySource.values.reduce((a, b) => asleepSecs(a) >= asleepSecs(b) ? a : b);

      // Generic "asleep" samples cover the same time as staged ones; keep them only when unstaged.
      final hasStages = chosen.any((p) =>
          p.type == HealthDataType.SLEEP_DEEP ||
          p.type == HealthDataType.SLEEP_LIGHT ||
          p.type == HealthDataType.SLEEP_REM);
      if (hasStages) {
        chosen = chosen.where((p) => p.type != HealthDataType.SLEEP_ASLEEP).toList();
      }
      chosen.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

      return chosen
          .map((p) => {
                'stage': _mapTypeToStage(p.type),
                'startTime': p.dateFrom.toUtc().toIso8601String(),
                'endTime': p.dateTo.toUtc().toIso8601String(),
                'durationSecs': p.dateTo.difference(p.dateFrom).inSeconds,
              })
          .toList();
    } catch (e) {
      debugPrint('[HealthKitService] Error fetching sleep stages: $e');
      return [];
    }
  }

  /// Fetch overnight heart rate samples.
  /// Window: 6:00 PM yesterday to 9:00 PM today to cover late morning & afternoon sleepers.
  Future<List<Map<String, dynamic>>> fetchOvernightHR(DateTime date) async {
    if (!Platform.isIOS) return [];

    try {
      final start = DateTime(date.year, date.month, date.day - 1, 18, 0);
      final end = DateTime(date.year, date.month, date.day, 21, 0);

      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );

      final result = <Map<String, dynamic>>[];
      for (final p in points) {
        num? val;
        if (p.value is NumericHealthValue) {
          val = (p.value as NumericHealthValue).numericValue;
        }

        if (val != null && val > 0) {
          result.add({
            'timestamp': p.dateFrom.toUtc().toIso8601String(),
            'bpm': val.round(),
            'context': 'sleep',
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint('[HealthKitService] Error fetching overnight HR: $e');
      return [];
    }
  }

  String? _mapTypeToStage(HealthDataType type) {
    switch (type) {
      case HealthDataType.SLEEP_DEEP:
        return 'deep';
      case HealthDataType.SLEEP_LIGHT:
      case HealthDataType.SLEEP_ASLEEP:
        return 'light';
      case HealthDataType.SLEEP_REM:
        return 'rem';
      case HealthDataType.SLEEP_AWAKE:
        return 'awake';
      default:
        return null;
    }
  }
}
