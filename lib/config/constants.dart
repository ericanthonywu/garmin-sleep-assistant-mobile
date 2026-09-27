class AppConstants {
  AppConstants._();

  // Backend URL on VPS (Hostinger)
  // For local development on same Wi-Fi, change to your Mac's LAN IP if running backend locally.
  static String apiBaseUrl = 'http://srv1743851.hstgr.cloud:3002/api';

  // ntfy.sh topic for push alerts
  static String ntfyTopic = 'momcare-7b3f9c42-881a-4d2a-9e12-3489fe0b21a8';

  // Sleep targets
  static const double sleepTargetHours = 8.0;
  static const String bedtimeTarget = '00:00';
  static const int minDeepSleepMinutes = 60;
  static const int minRemSleepMinutes = 90;
}
