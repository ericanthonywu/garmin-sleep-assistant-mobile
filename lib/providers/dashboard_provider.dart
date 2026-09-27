import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class SelectedDateNotifier extends Notifier<String> {
  @override
  String build() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void setDate(String newDate) => state = newDate;
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, String>(SelectedDateNotifier.new);

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final date = ref.watch(selectedDateProvider);
  final data = await api.getDashboard(date: date);

  // Auto-refresh iOS Home Screen widget with latest bedtime recommendation & date
  WidgetService.updateFromDashboard(data);

  return data;
});

