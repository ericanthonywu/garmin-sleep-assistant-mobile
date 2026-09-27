import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garmin_momcare/app.dart';
import 'package:garmin_momcare/models/dashboard_data.dart';
import 'package:garmin_momcare/providers/dashboard_provider.dart';

void main() {
  testWidgets('MomCareApp renders correctly with dashboard data', (WidgetTester tester) async {
    final mockData = DashboardData(
      date: '2026-09-27',
      sleepScore: 85,
      sleepHours: 7.5,
      restingHR: 58,
      hrv: 65,
      vo2max: 48.0,
      bodyBatteryHigh: 95,
      bodyBatteryLow: 25,
      steps: 8500,
      deepSleepMins: 90,
      lightSleepMins: 240,
      remSleepMins: 110,
      awakeMins: 10,
      bedtime: '2026-09-26T23:45:00',
      wakeTime: '2026-09-27T07:15:00',
      morningNote: 'Good morning sayang! Mama is proud you slept on time! ❤️',
      morningVerdict: 'good',
      weeklyChart: [],
      sleepStages: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith((ref) => Future.value(mockData)),
        ],
        child: const MomCareApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MomCareApp), findsOneWidget);
    expect(find.text('85'), findsOneWidget); // Sleep score
    expect(find.text('Mama says:'), findsOneWidget);
  });
}
