import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_data.dart';

/// Utility class to bridge Sleep & Bedtime recommendations to iOS WidgetKit
/// matching the pattern from mini-personal-app.
class WidgetService {
  WidgetService._();

  /// iOS App Group identifier matching Runner and Widget extension entitlements
  static const _appGroupId = 'group.com.ericanthony.garminMomcare';

  /// The Widget kind string matching `SleepWidget.kind` in Swift
  static const _widgetKind = 'SleepWidget';

  /// Initialize HomeWidget App Group
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {
      // Failing silently on simulator or unsupported platform
    }
  }

  /// Saves today's sleep recommendation to App Group UserDefaults and triggers widget reload
  static Future<void> updateFromDashboard(DashboardData data) async {
    final rec = data.sleepEngineRecommendation;
    if (rec == null) return;

    try {
      await HomeWidget.setAppGroupId(_appGroupId);

      final dt = DateTime.tryParse(data.date) ?? DateTime.now();
      final formattedDate = DateFormat('EEEE, MMM d').format(dt); // e.g. "Sunday, Sep 27"

      await HomeWidget.saveWidgetData<String>('target_bedtime', rec.recommendedBedtime);
      await HomeWidget.saveWidgetData<String>('cutoff_time', rec.latestBedtimeCutoff);
      await HomeWidget.saveWidgetData<String>('formatted_date', formattedDate);
      await HomeWidget.saveWidgetData<String>('date_iso', data.date);
      await HomeWidget.saveWidgetData<String>('wake_time', rec.targetWakeTime);
      await HomeWidget.saveWidgetData<String>('wind_down_start', rec.windDownStart);
      await HomeWidget.saveWidgetData<String>('sleep_onset', rec.recommendedSleepOnset);
      await HomeWidget.saveWidgetData<String>(
        'status_text',
        'In Bed: ${rec.recommendedBedtime} • Cutoff: ${rec.latestBedtimeCutoff}',
      );
      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateFormat('HH:mm').format(DateTime.now()),
      );

      await refreshWidget();
    } catch (_) {
      // Widget persistence is non-blocking
    }
  }

  /// Request iOS WidgetKit to reload the timeline for all SleepWidget instances
  static Future<void> refreshWidget() async {
    try {
      await HomeWidget.updateWidget(
        iOSName: _widgetKind,
        qualifiedAndroidName: '',
      );
    } catch (_) {
      // Failing silently is acceptable
    }
  }
}
