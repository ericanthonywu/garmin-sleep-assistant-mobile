import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/dashboard_data.dart';
import '../models/sleep_recommendation.dart';
import '../models/chat_message.dart';
import '../models/sleep_calendar_data.dart';

class ApiService {
  late final Dio _dio;

  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    AppConstants.apiBaseUrl = newUrl;
  }

  Future<DashboardData> getDashboard({String? date}) async {
    final res = await _dio.get(
      '/dashboard',
      queryParameters: date != null ? {'date': date} : null,
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return DashboardData.fromJson(data);
  }

  Future<Map<String, dynamic>> getSleepDetail(String date) async {
    final res = await _dio.get('/sleep/$date');
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<SleepCalendarResponse> getSleepCalendar({String? month, String? startDate, String? endDate}) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final res = await _dio.get(
      '/sleep/calendar',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final data = res.data['data'] as Map<String, dynamic>;
    return SleepCalendarResponse.fromJson(data);
  }

  Future<SleepRecommendation> getSleepRecommendation(String date) async {
    final res = await _dio.get('/sleep-engine/$date');
    final data = res.data['data'] as Map<String, dynamic>;
    return SleepRecommendation.fromJson(data);
  }

  Future<Map<String, dynamic>> syncHealthData({
    required String date,
    required List<Map<String, dynamic>> sleepStages,
    required List<Map<String, dynamic>> heartRateSamples,
    String? bedtime,
    String? wakeTime,
    double? sleepHours,
    int? sleepScore,
  }) async {
    final payload = <String, dynamic>{
      'date': date,
      'sleepStages': sleepStages,
      'heartRateSamples': heartRateSamples,
    };
    if (bedtime != null) payload['bedtime'] = bedtime;
    if (wakeTime != null) payload['wakeTime'] = wakeTime;
    if (sleepHours != null) payload['sleepHours'] = sleepHours;
    if (sleepScore != null) payload['sleepScore'] = sleepScore;

    final res = await _dio.post('/health/sync', data: payload);
    return res.data as Map<String, dynamic>;
  }

  Future<void> triggerIntervalsSync() async {
    await _dio.post('/sync/intervals');
  }

  Future<List<ChatMessage>> getChatHistory() async {
    final res = await _dio.get('/chat/history');
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> logMagnesium({
    required String date,
    required bool taken,
    String? dosage,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'date': date,
      'taken': taken,
      'dosage': ?dosage,
      'notes': ?notes,
    };
    final res = await _dio.post('/supplements/magnesium', data: payload);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMagnesiumStatus({String? date}) async {
    final res = await _dio.get(
      '/supplements/magnesium',
      queryParameters: date != null ? {'date': date} : null,
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> sendMagnesiumReminder() async {
    await _dio.post('/supplements/magnesium/remind');
  }
}
