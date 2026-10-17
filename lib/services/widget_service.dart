import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../models/dashboard_data.dart';
import '../models/sleep_recommendation.dart';
import '../utils/time_formatter.dart';

/// Utility class to bridge Sleep & Bedtime recommendations to iOS WidgetKit
/// matching the pattern from mini-personal-app.
class WidgetService {
  WidgetService._();

  /// iOS App Group identifier matching Runner and Widget extension entitlements
  static const _appGroupId = 'group.com.ericanthony.garminMomcare';

  /// The Widget kind string matching `SleepWidget.kind` in Swift
  static const _widgetKind = 'SleepWidget';

  /// Initialize HomeWidget App Group and seed initial defaults if empty
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<String>('base_url', AppConstants.apiBaseUrl);

      // Check if widget has been initialized; if not, seed realistic defaults
      final existingBedtime = await HomeWidget.getWidgetData<String>('target_bedtime');
      if (existingBedtime == null || existingBedtime.isEmpty) {
        await saveInitialDefaults();
      }
    } catch (e) {
      debugPrint('[WidgetService] init error: $e');
    }
  }

  /// Initial sample data so the widget is populated immediately when placed
  static Future<void> saveInitialDefaults() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final now = DateTime.now();
      final formattedDate = DateFormat('EEEE, MMM d').format(now);
      final todayShort = DateFormat('EEE, d MMM').format(now);

      await HomeWidget.saveWidgetData<String>('target_bedtime', '11:30 PM');
      await HomeWidget.saveWidgetData<String>('wind_down_start', '10:45 PM');
      await HomeWidget.saveWidgetData<String>('baseline_bedtime', '12:00 AM');
      await HomeWidget.saveWidgetData<String>('cutoff_time', '12:15 AM');
      await HomeWidget.saveWidgetData<String>('wake_time', '07:30 AM');
      await HomeWidget.saveWidgetData<String>('sleep_onset', '12:00 AM');
      await HomeWidget.saveWidgetData<String>('baseline_wake', '07:45 AM');
      await HomeWidget.saveWidgetData<String>('sleep_need', '7h 45m');
      await HomeWidget.saveWidgetData<String>('formatted_date', formattedDate);
      await HomeWidget.saveWidgetData<String>('today_short', todayShort);
      await HomeWidget.saveWidgetData<String>('status_text', 'Optimal circadian window');
      await HomeWidget.saveWidgetData<String>('adherence_status', 'holding');
      await HomeWidget.saveWidgetData<int>('shift_minutes', 15);
      await HomeWidget.saveWidgetData<String>('guidance', 'Wind down 45m before bed to consolidate circadian rhythm.');
      await HomeWidget.saveWidgetData<String>('last_updated', DateFormat('HH:mm').format(now));

      await refreshWidget();
    } catch (_) {}
  }

  /// Saves today's sleep recommendation to App Group UserDefaults and triggers widget reload
  static Future<void> updateFromDashboard(DashboardData data) async {
    final rec = data.sleepEngineRecommendation;
    if (rec == null) return;

    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final dt = DateTime.tryParse(data.date) ?? DateTime.now();
      final formattedDate = DateFormat('EEEE, MMM d').format(dt); // e.g. "Monday, Sep 29"
      final todayShort = DateFormat('EEE, d MMM').format(dt);     // e.g. "Mon, 29 Sep"

      // Format times into readable 12-hour strings e.g. "11:30 PM"
      final targetBedtime = TimeFormatter.formatTime(rec.recommendedBedtime);
      final windDownStart = rec.windDownStart != null ? TimeFormatter.formatTime(rec.windDownStart) : '10:45 PM';
      final baselineBedtime = TimeFormatter.formatTime(rec.anchorBedtime);
      final cutoffTime = rec.latestBedtimeCutoff != null ? TimeFormatter.formatTime(rec.latestBedtimeCutoff) : '12:15 AM';
      final wakeTime = rec.targetWakeTime != null ? TimeFormatter.formatTime(rec.targetWakeTime) : '07:30 AM';
      final sleepOnset = TimeFormatter.formatTime(rec.recommendedSleepOnset);
      final baselineWake = rec.habitualWakeTime != null ? TimeFormatter.formatTime(rec.habitualWakeTime) : '07:45 AM';

      final sleepNeed = rec.sleepNeedMins != null
          ? TimeFormatter.formatDurationMinutes(rec.sleepNeedMins!)
          : (rec.sleepNeedHours != null ? '${rec.sleepNeedHours!.toStringAsFixed(1)}h' : '7h 30m');

      final statusText = _deriveStatusSubtitle(rec);

      await HomeWidget.saveWidgetData<String>('target_bedtime', targetBedtime);
      await HomeWidget.saveWidgetData<String>('wind_down_start', windDownStart);
      await HomeWidget.saveWidgetData<String>('baseline_bedtime', baselineBedtime);
      await HomeWidget.saveWidgetData<String>('cutoff_time', cutoffTime);
      await HomeWidget.saveWidgetData<String>('wake_time', wakeTime);
      await HomeWidget.saveWidgetData<String>('sleep_onset', sleepOnset);
      await HomeWidget.saveWidgetData<String>('baseline_wake', baselineWake);
      await HomeWidget.saveWidgetData<String>('sleep_need', sleepNeed);
      await HomeWidget.saveWidgetData<String>('formatted_date', formattedDate);
      await HomeWidget.saveWidgetData<String>('today_short', todayShort);
      await HomeWidget.saveWidgetData<String>('date_iso', data.date);
      await HomeWidget.saveWidgetData<String>('status_text', statusText);
      await HomeWidget.saveWidgetData<String>('adherence_status', rec.adherenceStatus);
      await HomeWidget.saveWidgetData<int>('shift_minutes', rec.shiftMinutes);
      await HomeWidget.saveWidgetData<String>('guidance', rec.guidance);
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateFormat('HH:mm').format(DateTime.now()),
      );

      debugPrint('[WidgetService] Saved widget data (Bedtime: $targetBedtime, Cutoff: $cutoffTime)');
      await refreshWidget();
    } catch (e, st) {
      debugPrint('[WidgetService] Error saving widget data: $e\n$st');
    }
  }

  static String _deriveStatusSubtitle(SleepRecommendation rec) {
    switch (rec.adherenceStatus) {
      case 'advancing':
        return '${rec.stepMinutes}m earlier step';
      case 'holding':
        return rec.holdReason == 'consolidating' ? 'Settling in' : 'Holding steady';
      case 'regressing':
        return 'Anchored · resume soon';
      case 'achieved':
        return 'Goal achieved ✓';
      default:
        return 'Optimal window';
    }
  }

  /// Request iOS WidgetKit to reload the timeline for all SleepWidget instances
  static Future<void> refreshWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: _widgetKind,
        iOSName: _widgetKind,
        qualifiedAndroidName: '',
      );
      debugPrint('[WidgetService] Successfully requested reload for $_widgetKind');
    } catch (e) {
      debugPrint('[WidgetService] Error requesting reload for $_widgetKind: $e');
    }
  }
}
