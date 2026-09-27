import 'package:intl/intl.dart';

class TimeFormatter {
  TimeFormatter._();

  /// Formats a time string (either 'HH:mm' or ISO 8601) to a readable 12-hour format like '11:30 PM'.
  static String formatTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '--';

    // 1. Try ISO string first if it has date separators
    if (timeStr.contains('T')) {
      final parsed = DateTime.tryParse(timeStr);
      if (parsed != null) {
        return DateFormat('h:mm a').format(parsed.toLocal());
      }
    }

    // 2. Try 'HH:mm' or 'H:mm'
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMin = minute.toString().padLeft(2, '0');
        return '$displayHour:$displayMin $period';
      }
    }

    return timeStr;
  }

  /// Formats a time string into 24-hour 'HH:mm'.
  static String format24h(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return '--';

    if (timeStr.contains('T')) {
      final parsed = DateTime.tryParse(timeStr);
      if (parsed != null) {
        final dt = parsed.toLocal();
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }

    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
    }

    return timeStr;
  }

  /// Extracts hour and minute from a string ('HH:mm' or ISO).
  static ({int hour, int minute})? parseTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;

    if (timeStr.contains('T')) {
      final parsed = DateTime.tryParse(timeStr);
      if (parsed != null) {
        final dt = parsed.toLocal();
        return (hour: dt.hour, minute: dt.minute);
      }
    }

    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return (hour: hour, minute: minute);
      }
    }

    return null;
  }

  /// Converts an (hour, minute) into minutes past 12:00 PM (noon).
  /// Range is [0, 1439]:
  /// 12:00 PM = 0
  /// 20:00 (8 PM) = 480
  /// 23:30 (11:30 PM) = 690
  /// 00:00 (midnight) = 720
  /// 07:10 (7:10 AM) = 1150
  /// 11:59 AM next day = 1439
  static int toMinutesPastNoon(int hour, int minute) {
    if (hour >= 12) {
      return (hour - 12) * 60 + minute;
    } else {
      return (hour + 12) * 60 + minute;
    }
  }

  /// Formats minutes into 'Xh Ym' or 'Ym'.
  static String formatDurationMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}
