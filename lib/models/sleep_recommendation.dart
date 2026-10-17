class SleepRecommendation {
  final String anchorBedtime;
  final String recommendedBedtime;
  final String? latestBedtimeCutoff;
  final String? targetWakeTime;
  final String? windDownStart;
  final int shiftMinutes; // earlier than the habitual onset
  final int stepMinutes; // earlier than last night's target
  final int socialJetlag;
  final String adherenceStatus; // 'advancing', 'holding', 'regressing', 'achieved', 'no_data'
  final String? holdReason; // 'consolidating', 'missed', 'lead_cap', 'late_wake', 'short_night'
  final String guidance;
  
  // New fields
  final String recommendedSleepOnset;
  final String? dimLightsStart;
  final String? magnesiumReminderTime;
  final String? habitualWakeTime;
  final double? sleepNeedHours;
  final double? sleepDebtHours;
  final int? sleepNeedMins;
  final int? sleepDebtMins;
  final int? onsetVariabilityMins;
  final int? nightsAnalyzed;
  final int? outlierNights;

  SleepRecommendation({
    required this.anchorBedtime,
    required this.recommendedBedtime,
    this.latestBedtimeCutoff,
    this.targetWakeTime,
    this.windDownStart,
    required this.shiftMinutes,
    this.stepMinutes = 0,
    required this.socialJetlag,
    required this.adherenceStatus,
    this.holdReason,
    required this.guidance,
    required this.recommendedSleepOnset,
    this.dimLightsStart,
    this.magnesiumReminderTime,
    this.habitualWakeTime,
    this.sleepNeedHours,
    this.sleepDebtHours,
    this.sleepNeedMins,
    this.sleepDebtMins,
    this.onsetVariabilityMins,
    this.nightsAnalyzed,
    this.outlierNights,
  });

  factory SleepRecommendation.fromJson(Map<String, dynamic> json) {
    return SleepRecommendation(
      anchorBedtime: json['anchorBedtime'] ?? '00:00',
      recommendedBedtime: json['recommendedBedtime'] ?? '00:00',
      latestBedtimeCutoff: json['latestBedtimeCutoff'],
      targetWakeTime: json['targetWakeTime'],
      windDownStart: json['windDownStart'],
      shiftMinutes: json['shiftMinutes'] ?? 0,
      stepMinutes: (json['stepMinutes'] as num?)?.round() ?? 0,
      socialJetlag: json['socialJetlag'] ?? 0,
      adherenceStatus: json['adherenceStatus'] ?? 'holding',
      holdReason: json['holdReason'],
      guidance: json['guidance'] ?? '',
      recommendedSleepOnset: json['recommendedSleepOnset'] ?? '00:00',
      dimLightsStart: json['dimLightsStart'],
      magnesiumReminderTime: json['magnesiumReminderTime'],
      habitualWakeTime: json['habitualWakeTime'],
      sleepNeedHours: json['sleepNeedHours']?.toDouble(),
      sleepDebtHours: json['sleepDebtHours']?.toDouble(),
      sleepNeedMins: _minutes(json['sleepNeedMins'], json['sleepNeedHours']),
      sleepDebtMins: _minutes(json['sleepDebtMins'], json['sleepDebtHours']),
      onsetVariabilityMins: json['onsetVariabilityMins'],
      nightsAnalyzed: json['nightsAnalyzed'],
      outlierNights: json['outlierNights'],
    );
  }

  static int? _minutes(dynamic mins, dynamic hours) {
    if (mins is num) return mins.round();
    if (hours is num) return (hours * 60).round();
    return null;
  }
}
