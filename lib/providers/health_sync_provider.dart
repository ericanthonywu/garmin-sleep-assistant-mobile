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
      final healthKit = ref.read(healthKitServiceProvider);
      final permitted = await healthKit.requestPermissions();
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      if (!permitted) {
        return 'HealthKit permission not granted or device not supported.';
      }

      final sleepStages = await healthKit.fetchSleepStages(now);
      final hrSamples = await healthKit.fetchOvernightHR(now);

      final api = ref.read(apiServiceProvider);
      await api.syncHealthData(
        date: todayStr,
        sleepStages: sleepStages,
        heartRateSamples: hrSamples,
      );

      // Invalidate dashboard to trigger instant refresh
      ref.invalidate(dashboardProvider);

      return 'Synced ${sleepStages.length} sleep stages & ${hrSamples.length} HR points!';
    });
  }
}

final healthSyncProvider = AsyncNotifierProvider<HealthSyncNotifier, String?>(HealthSyncNotifier.new);
