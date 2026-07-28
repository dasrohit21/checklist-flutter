import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mission.dart';
import '../models/mission_behavior_analysis.dart';
import '../models/mission_chain.dart';
import '../models/mission_workspace_data.dart';
import '../models/target_item.dart';

/// Service coordinating Mission Workspace metadata, parent chain lookups,
/// notes auto-save, and health explanations.
class MissionDetailsService {
  static const String _prefix = 'mission_workspace_data_';

  /// Loads workspace metadata for a given target ID.
  static Future<MissionWorkspaceData> loadWorkspaceData(String targetId) async {
    if (targetId.isEmpty) return MissionWorkspaceData.empty(targetId);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$targetId');
    if (raw == null || raw.isEmpty) return MissionWorkspaceData.empty(targetId);

    try {
      return MissionWorkspaceData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return MissionWorkspaceData.empty(targetId);
    }
  }

  /// Saves workspace metadata for a given target ID.
  static Future<void> saveWorkspaceData(MissionWorkspaceData data) async {
    if (data.targetId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix${data.targetId}', jsonEncode(data.toJson()));
  }

  /// Auto-saves updated notes for a target ID and updates the notesLastEdited timestamp.
  static Future<MissionWorkspaceData> autoSaveNotes({
    required String targetId,
    required String notes,
  }) async {
    final data = await loadWorkspaceData(targetId);
    final updated = data.copyWith(notesLastEdited: DateTime.now());
    await saveWorkspaceData(updated);
    return updated;
  }

  /// Finds the parent [MissionChain] containing this target ID.
  static MissionChain? findParentChain(String targetId, List<MissionChain> chains) {
    if (targetId.isEmpty) return null;
    for (final chain in chains) {
      if (chain.targetIds.contains(targetId)) return chain;
    }
    return null;
  }

  /// Formats a concise explanation for a given [MissionHealthStatus].
  static String getHealthExplanation(MissionHealthStatus health, MissionBehaviorAnalysis? analysis) {
    if (analysis != null) {
      if (analysis.postponementsCount >= 3) {
        return 'Frequently postponed (${analysis.postponementsCount} times).';
      }
      if (analysis.completionPercentage >= 0.8) {
        return 'Completion rate remains high (${(analysis.completionPercentage * 100).round()}%).';
      }
    }

    return switch (health) {
      MissionHealthStatus.excellent => 'Completion rate remains high. Steady progress.',
      MissionHealthStatus.good => 'Progressing steadily according to plan.',
      MissionHealthStatus.warning => 'Frequently postponed or stalled recently.',
      MissionHealthStatus.critical => 'Critical delay. High postponement or inactivity.',
    };
  }

  /// Returns the current lifecycle status string for a target item.
  static String getMissionStatusLabel({
    required TargetItem target,
    required bool isArchived,
    required Mission? activeMission,
  }) {
    if (isArchived) return 'Archived';
    if (target.solvedCount >= target.targetCount && target.targetCount > 0) {
      return 'Completed';
    }
    if (activeMission != null && activeMission.targetId == target.id) {
      return activeMission.isPaused ? 'Paused' : 'In Progress';
    }
    if (target.solvedCount > 0) return 'In Progress';
    return 'Not Started';
  }
}
