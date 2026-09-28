class SleepRecommendation {
  final String anchorBedtime;
  final String recommendedBedtime;
  final String? latestBedtimeCutoff;
  final String? targetWakeTime;
  final String? windDownStart;
  final int shiftMinutes;
  final int socialJetlag;
  final String adherenceStatus; // 'advancing', 'holding', 'regressing', 'achieved', 'no_data'
  final String guidance;
  
  // New fields
  final String recommendedSleepOnset;
  final String? dimLightsStart;
  final String? habitualWakeTime;
  final double? sleepNeedHours;
  final double? sleepDebtHours;
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
    required this.socialJetlag,
    required this.adherenceStatus,
    required this.guidance,
    required this.recommendedSleepOnset,
    this.dimLightsStart,
    this.habitualWakeTime,
    this.sleepNeedHours,
    this.sleepDebtHours,
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
      socialJetlag: json['socialJetlag'] ?? 0,
      adherenceStatus: json['adherenceStatus'] ?? 'holding',
      guidance: json['guidance'] ?? '',
      recommendedSleepOnset: json['recommendedSleepOnset'] ?? '00:00',
      dimLightsStart: json['dimLightsStart'],
      habitualWakeTime: json['habitualWakeTime'],
      sleepNeedHours: json['sleepNeedHours']?.toDouble(),
      sleepDebtHours: json['sleepDebtHours']?.toDouble(),
      onsetVariabilityMins: json['onsetVariabilityMins'],
      nightsAnalyzed: json['nightsAnalyzed'],
      outlierNights: json['outlierNights'],
    );
  }
}
