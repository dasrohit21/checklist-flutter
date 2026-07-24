import 'mission_behavior_analysis.dart';

/// Aggregated output from the Behavior Intelligence Engine.
class BehaviorSummary {
  final Map<String, MissionBehaviorAnalysis> missionHealthMap;
  final List<String> behaviorInsights;
  final List<String> recommendations;
  final DateTime lastAnalyzed;

  const BehaviorSummary({
    required this.missionHealthMap,
    required this.behaviorInsights,
    required this.recommendations,
    required this.lastAnalyzed,
  });

  factory BehaviorSummary.empty() => BehaviorSummary(
        missionHealthMap: const {},
        behaviorInsights: const [],
        recommendations: const [],
        lastAnalyzed: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'missionHealthMap':
            missionHealthMap.map((k, v) => MapEntry(k, v.toJson())),
        'behaviorInsights': behaviorInsights,
        'recommendations': recommendations,
        'lastAnalyzed': lastAnalyzed.toIso8601String(),
      };

  factory BehaviorSummary.fromJson(Map<String, dynamic> json) =>
      BehaviorSummary(
        missionHealthMap: (json['missionHealthMap']
                    as Map<String, dynamic>? ??
                {})
            .map((k, v) => MapEntry(
                k, MissionBehaviorAnalysis.fromJson(v as Map<String, dynamic>))),
        behaviorInsights: (json['behaviorInsights'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        recommendations: (json['recommendations'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toList(),
        lastAnalyzed: DateTime.tryParse(json['lastAnalyzed'] as String? ?? '') ??
            DateTime.now(),
      );
}
