import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/time_formatter.dart';
import 'dashboard_provider.dart';

class SleepEnforcementState {
  final bool isEnabled;
  final bool isPreviewing;
  final DateTime? snoozedUntil;
  final String? activeCutoff;
  final String? targetWake;

  const SleepEnforcementState({
    this.isEnabled = true,
    this.isPreviewing = false,
    this.snoozedUntil,
    this.activeCutoff,
    this.targetWake,
  });

  bool get shouldBlockApp {
    if (!isEnabled) return false;
    if (isPreviewing) return true;

    // If snoozed and snooze time is in future, don't block
    if (snoozedUntil != null && DateTime.now().isBefore(snoozedUntil!)) {
      return false;
    }

    final cutoff = activeCutoff ?? '00:45';
    final wake = targetWake ?? '07:30';

    final parsedCutoff = TimeFormatter.parseTime(cutoff);
    final parsedWake = TimeFormatter.parseTime(wake);

    if (parsedCutoff == null) return false;

    final now = DateTime.now();
    final currentMins = TimeFormatter.toMinutesPastNoon(now.hour, now.minute);
    final cutoffMins = TimeFormatter.toMinutesPastNoon(parsedCutoff.hour, parsedCutoff.minute);
    final wakeMins = parsedWake != null
        ? TimeFormatter.toMinutesPastNoon(parsedWake.hour, parsedWake.minute)
        : (cutoffMins + 420); // default +7 hours

    // Enforcement window starts 30 minutes before the latest cutoff and ends at wake time
    final windowStartMins = cutoffMins - 30;

    // Normal night window: windowStartMins to wakeMins
    if (windowStartMins <= wakeMins) {
      return currentMins >= windowStartMins && currentMins < wakeMins;
    } else {
      // In case wakeMins is earlier past noon (rare edge case)
      return currentMins >= windowStartMins || currentMins < wakeMins;
    }
  }

  SleepEnforcementState copyWith({
    bool? isEnabled,
    bool? isPreviewing,
    DateTime? snoozedUntil,
    String? activeCutoff,
    String? targetWake,
  }) {
    return SleepEnforcementState(
      isEnabled: isEnabled ?? this.isEnabled,
      isPreviewing: isPreviewing ?? this.isPreviewing,
      snoozedUntil: snoozedUntil,
      activeCutoff: activeCutoff ?? this.activeCutoff,
      targetWake: targetWake ?? this.targetWake,
    );
  }
}

class SleepEnforcementNotifier extends Notifier<SleepEnforcementState> {
  Timer? _ticker;

  @override
  SleepEnforcementState build() {
    // Check every 30 seconds to evaluate if current time entered the enforcement window
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      state = state.copyWith();
    });

    ref.onDispose(() {
      _ticker?.cancel();
    });

    // Listen to dashboard recommendations to extract active cutoff and target wake times
    ref.listen(dashboardProvider, (prev, next) {
      final rec = next.value?.sleepEngineRecommendation;
      if (rec != null) {
        state = state.copyWith(
          activeCutoff: rec.latestBedtimeCutoff ?? '00:45',
          targetWake: rec.targetWakeTime ?? '07:30',
        );
      }
    });

    return const SleepEnforcementState(
      activeCutoff: '00:45',
      targetWake: '07:30',
    );
  }

  void toggleEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  void previewOverlay() {
    state = state.copyWith(isPreviewing: true);
  }

  void closePreview() {
    state = state.copyWith(isPreviewing: false);
  }

  void snooze15Minutes() {
    final snoozeEnd = DateTime.now().add(const Duration(minutes: 15));
    state = state.copyWith(
      isPreviewing: false,
      snoozedUntil: snoozeEnd,
    );
  }

  void dismissForNight() {
    // Snooze for 8 hours (rest of night)
    final snoozeEnd = DateTime.now().add(const Duration(hours: 8));
    state = state.copyWith(
      isPreviewing: false,
      snoozedUntil: snoozeEnd,
    );
  }
}

final sleepEnforcementProvider =
    NotifierProvider<SleepEnforcementNotifier, SleepEnforcementState>(
  SleepEnforcementNotifier.new,
);
