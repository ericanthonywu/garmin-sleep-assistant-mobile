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

  /// Fetch sleep intervals for target date.
  /// Window: 6:00 PM yesterday to 2:00 PM today.
  Future<List<Map<String, dynamic>>> fetchSleepStages(DateTime date) async {
    if (!Platform.isIOS) return [];

    try {
      final start = DateTime(date.year, date.month, date.day - 1, 18, 0);
      final end = DateTime(date.year, date.month, date.day, 14, 0);

      final points = await _health.getHealthDataFromTypes(
        types: [
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_REM,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_ASLEEP,
        ],
        startTime: start,
        endTime: end,
      );

      final result = <Map<String, dynamic>>[];
      for (final p in points) {
        final stage = _mapTypeToStage(p.type);
        if (stage == null) continue;

        final duration = p.dateTo.difference(p.dateFrom).inSeconds;
        if (duration <= 0) continue;

        result.add({
          'stage': stage,
          'startTime': p.dateFrom.toIso8601String(),
          'endTime': p.dateTo.toIso8601String(),
          'durationSecs': duration,
        });
      }

      return result;
    } catch (e) {
      debugPrint('[HealthKitService] Error fetching sleep stages: $e');
      return [];
    }
  }

  /// Fetch overnight heart rate samples.
  Future<List<Map<String, dynamic>>> fetchOvernightHR(DateTime date) async {
    if (!Platform.isIOS) return [];

    try {
      final start = DateTime(date.year, date.month, date.day - 1, 22, 0);
      final end = DateTime(date.year, date.month, date.day, 11, 0);

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
            'timestamp': p.dateFrom.toIso8601String(),
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
