class SleepCalendarDay {
  final String date;
  final bool hasData;
  final int? sleepScore;
  final String? sleepScoreQuality; // 'optimal', 'good', 'fair', 'poor'
  final double? sleepHours;
  final int? sleepSecs;
  final String? sleepFormatted;
  final String? bedtime;
  final String? wakeTime;
  final int? restingHR;
  final int? hrv;
  final int deepSleepMins;
  final int lightSleepMins;
  final int remSleepMins;
  final int awakeMins;
  final bool magnesiumTaken;
  final String? morningVerdict;
  final String? morningNote;

  const SleepCalendarDay({
    required this.date,
    this.hasData = false,
    this.sleepScore,
    this.sleepScoreQuality,
    this.sleepHours,
    this.sleepSecs,
    this.sleepFormatted,
    this.bedtime,
    this.wakeTime,
    this.restingHR,
    this.hrv,
    this.deepSleepMins = 0,
    this.lightSleepMins = 0,
    this.remSleepMins = 0,
    this.awakeMins = 0,
    this.magnesiumTaken = false,
    this.morningVerdict,
    this.morningNote,
  });

  factory SleepCalendarDay.fromJson(Map<String, dynamic> json) {
    return SleepCalendarDay(
      date: json['date'] as String,
      hasData: json['hasData'] as bool? ?? false,
      sleepScore: (json['sleepScore'] as num?)?.toInt(),
      sleepScoreQuality: json['sleepScoreQuality'] as String?,
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      sleepSecs: (json['sleepSecs'] as num?)?.toInt(),
      sleepFormatted: json['sleepFormatted'] as String?,
      bedtime: json['bedtime'] as String?,
      wakeTime: json['wakeTime'] as String?,
      restingHR: (json['restingHR'] as num?)?.toInt(),
      hrv: (json['hrv'] as num?)?.toInt(),
      deepSleepMins: (json['deepSleepMins'] as num?)?.toInt() ?? 0,
      lightSleepMins: (json['lightSleepMins'] as num?)?.toInt() ?? 0,
      remSleepMins: (json['remSleepMins'] as num?)?.toInt() ?? 0,
      awakeMins: (json['awakeMins'] as num?)?.toInt() ?? 0,
      magnesiumTaken: json['magnesiumTaken'] as bool? ?? false,
      morningVerdict: json['morningVerdict'] as String?,
      morningNote: json['morningNote'] as String?,
    );
  }
}

class SleepCalendarStats {
  final int totalNightsTracked;
  final int? averageSleepScore;
  final double? averageSleepHours;
  final int optimalNights;
  final int goodNights;
  final int fairNights;
  final int poorNights;
  final int magnesiumAdherenceRate;

  const SleepCalendarStats({
    this.totalNightsTracked = 0,
    this.averageSleepScore,
    this.averageSleepHours,
    this.optimalNights = 0,
    this.goodNights = 0,
    this.fairNights = 0,
    this.poorNights = 0,
    this.magnesiumAdherenceRate = 0,
  });

  factory SleepCalendarStats.fromJson(Map<String, dynamic> json) {
    return SleepCalendarStats(
      totalNightsTracked: (json['totalNightsTracked'] as num?)?.toInt() ?? 0,
      averageSleepScore: (json['averageSleepScore'] as num?)?.toInt(),
      averageSleepHours: (json['averageSleepHours'] as num?)?.toDouble(),
      optimalNights: (json['optimalNights'] as num?)?.toInt() ?? 0,
      goodNights: (json['goodNights'] as num?)?.toInt() ?? 0,
      fairNights: (json['fairNights'] as num?)?.toInt() ?? 0,
      poorNights: (json['poorNights'] as num?)?.toInt() ?? 0,
      magnesiumAdherenceRate: (json['magnesiumAdherenceRate'] as num?)?.toInt() ?? 0,
    );
  }
}

class SleepCalendarResponse {
  final String startDate;
  final String endDate;
  final List<SleepCalendarDay> days;
  final SleepCalendarStats? monthlyStats;

  const SleepCalendarResponse({
    required this.startDate,
    required this.endDate,
    required this.days,
    this.monthlyStats,
  });

  factory SleepCalendarResponse.fromJson(Map<String, dynamic> json) {
    final daysList = (json['days'] as List<dynamic>?) ?? [];
    return SleepCalendarResponse(
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      days: daysList.map((e) => SleepCalendarDay.fromJson(e as Map<String, dynamic>)).toList(),
      monthlyStats: json['monthlyStats'] != null
          ? SleepCalendarStats.fromJson(json['monthlyStats'] as Map<String, dynamic>)
          : null,
    );
  }
}
