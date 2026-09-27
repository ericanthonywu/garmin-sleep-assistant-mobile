import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garmin_momcare/app.dart';
import 'package:garmin_momcare/models/dashboard_data.dart';
import 'package:garmin_momcare/providers/dashboard_provider.dart';
import 'package:garmin_momcare/screens/dashboard/widgets/weekly_sleep_chart.dart';

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
      morningNote: 'Good morning! You slept consistently well.',
      morningVerdict: 'good',
      weeklyChart: [
        WeeklySleepItem(
          date: '2026-09-26',
          sleepHours: 7.5,
          sleepScore: 84,
          bedtime: '23:45',
          wakeTime: '07:15',
        ),
        WeeklySleepItem(
          date: '2026-09-27',
          sleepHours: 7.7,
          sleepScore: 88,
          bedtime: '23:30',
          wakeTime: '07:10',
        ),
      ],
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
    expect(find.text('Morning Briefing'), findsOneWidget);
    expect(find.text('HISTORICAL SLEEP & WAKE SCHEDULE'), findsOneWidget);
  });

  testWidgets('WeeklySleepChart renders bed and wake schedule and toggles views', (WidgetTester tester) async {
    final mockWeekly = [
      WeeklySleepItem(
        date: '2026-09-21',
        sleepHours: 6.5,
        sleepScore: 74,
        bedtime: '00:30',
        wakeTime: '07:00',
      ),
      WeeklySleepItem(
        date: '2026-09-22',
        sleepHours: 7.0,
        sleepScore: 79,
        bedtime: '00:15',
        wakeTime: '07:15',
      ),
      WeeklySleepItem(
        date: '2026-09-23',
        sleepHours: 6.0,
        sleepScore: 68,
        bedtime: '01:00',
        wakeTime: '07:00',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WeeklySleepChart(weeklyData: mockWeekly),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify Title & View Toggle
    expect(find.text('HISTORICAL SLEEP & WAKE SCHEDULE'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Duration'), findsWidgets);

    // Verify Schedule View Guidelines
    expect(find.text('🎯 Target 12:00 AM'), findsOneWidget);

    // Toggle to Duration View
    await tester.tap(find.text('Duration').first);
    await tester.pump();


    expect(find.text('>=7h'), findsOneWidget);
    expect(find.text('6-7h'), findsOneWidget);

    // Toggle back to Schedule View
    await tester.tap(find.text('Schedule'));
    await tester.pump();

    // Expand 7-Day History Table
    expect(find.text('View 7-Day History Table'), findsOneWidget);
    await tester.tap(find.text('View 7-Day History Table'));
    await tester.pump();

    expect(find.text('Hide Daily History Table'), findsOneWidget);
    expect(find.text('Bedtime'), findsOneWidget);
    expect(find.text('Wake'), findsOneWidget);
  });
}
