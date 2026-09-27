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
    );
  }
}
