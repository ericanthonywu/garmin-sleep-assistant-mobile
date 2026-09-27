import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/healthkit_service.dart';
import 'dashboard_provider.dart';

final healthKitServiceProvider = Provider<HealthKitService>((ref) {
  return HealthKitService();
});

class HealthSyncNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() => null;

  Future<void> syncNow() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiServiceProvider);

      // 1. Trigger Intervals.icu cloud sync on backend
      try {
        await api.triggerIntervalsSync();
      } catch (e) {
        // Non-blocking warning if network hiccups
      }

      final healthKit = ref.read(healthKitServiceProvider);
      final permitted = await healthKit.requestPermissions();
      final now = DateTime.now();

      if (!permitted) {
        // If HealthKit is not permitted on this device (e.g. simulator), refresh dashboard from backend
        ref.invalidate(dashboardProvider);
        return 'Updated from Garmin & Intervals.icu cloud.';
      }

      int totalSyncedDays = 0;
      // 2. Sync past 7 days of sleep and HR data from Apple HealthKit
      for (int i = 6; i >= 0; i--) {
        final targetDate = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
        final sleepStages = await healthKit.fetchSleepStages(targetDate);
        final hrSamples = (i <= 1) ? await healthKit.fetchOvernightHR(targetDate) : <Map<String, dynamic>>[];

        String? localBedtime;
        String? localWakeTime;
        double? sleepHours;

        final validSleep = sleepStages.where((s) => s['stage'] != 'awake').toList();
        if (validSleep.isNotEmpty) {
          final first = DateTime.tryParse(validSleep.first['startTime'] as String? ?? '');
          final last = DateTime.tryParse(validSleep.last['endTime'] as String? ?? '');
          if (first != null) localBedtime = DateFormat('HH:mm').format(first);
          if (last != null) localWakeTime = DateFormat('HH:mm').format(last);
          final totalSecs = validSleep.fold<int>(0, (sum, s) => sum + (s['durationSecs'] as int? ?? 0));
          if (totalSecs > 0) sleepHours = totalSecs / 3600.0;
        }

        if (sleepStages.isNotEmpty || hrSamples.isNotEmpty) {
          await api.syncHealthData(
            date: dateStr,
            sleepStages: sleepStages,
            heartRateSamples: hrSamples,
            bedtime: localBedtime,
            wakeTime: localWakeTime,
            sleepHours: sleepHours,
          );
          totalSyncedDays++;
        }
      }

      // Invalidate dashboard to trigger instant refresh
      ref.invalidate(dashboardProvider);

      return totalSyncedDays > 0
          ? 'Successfully synced $totalSyncedDays days from Garmin & HealthKit!'
          : 'Sync complete (dashboard up to date).';
    });
  }
}

final healthSyncProvider = AsyncNotifierProvider<HealthSyncNotifier, String?>(HealthSyncNotifier.new);
