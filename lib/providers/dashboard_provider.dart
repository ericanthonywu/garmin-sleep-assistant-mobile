import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';

import '../models/sleep_calendar_data.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class SelectedDateNotifier extends Notifier<String> {
  @override
  String build() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void setDate(String newDate) => state = newDate;
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, String>(SelectedDateNotifier.new);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) => state = DateTime(month.year, month.month, 1);
  void previousMonth() => state = DateTime(state.year, state.month - 1, 1);
  void nextMonth() => state = DateTime(state.year, state.month + 1, 1);
  void currentMonth() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(SelectedMonthNotifier.new);

final sleepCalendarProvider = FutureProvider.autoDispose<SleepCalendarResponse>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final monthDate = ref.watch(selectedMonthProvider);
  final monthStr = DateFormat('yyyy-MM').format(monthDate);
  return api.getSleepCalendar(month: monthStr);
});

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final date = ref.watch(selectedDateProvider);
  final data = await api.getDashboard(date: date);

  // Auto-refresh iOS Home Screen widget with latest bedtime recommendation & date
  // Only update widget when viewing today's data so historical navigation doesn't overwrite the widget
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  if (data.date == todayStr || date == todayStr) {
    await WidgetService.updateFromDashboard(data);
  }

  return data;
});

class MagnesiumNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> toggleMagnesium({
    required String date,
    required bool taken,
    String? dosage,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiServiceProvider);
      await api.logMagnesium(
        date: date,
        taken: taken,
        dosage: dosage,
        notes: notes,
      );
      ref.invalidate(dashboardProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> sendTestReminder() async {
    final api = ref.read(apiServiceProvider);
    await api.sendMagnesiumReminder();
  }
}

final magnesiumProvider = AsyncNotifierProvider<MagnesiumNotifier, void>(MagnesiumNotifier.new);

