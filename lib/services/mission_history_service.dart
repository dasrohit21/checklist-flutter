import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission_timeline_event.dart';

/// Independent service for recording & managing mission timeline events.
///
/// Responsibilities:
///   - Persist chronological events per target ID.
///   - Load read-only timeline history for the Mission Workspace.
class MissionHistoryService {
  static const String _prefix = 'mission_timeline_';

  /// Loads the timeline event history for a specific mission target.
  static Future<List<MissionTimelineEvent>> loadTimeline(String targetId) async {
    if (targetId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$targetId');
    if (raw == null || raw.isEmpty) return const [];

    try {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      return jsonList
          .map((e) => MissionTimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Appends a new event to a mission's timeline history.
  static Future<void> recordEvent({
    required String targetId,
    required MissionTimelineEventType type,
    required String description,
  }) async {
    if (targetId.isEmpty) return;
    final timeline = await loadTimeline(targetId);
    final newEvent = MissionTimelineEvent(
      id: '${DateTime.now().millisecondsSinceEpoch}_${type.name}',
      targetId: targetId,
      type: type,
      timestamp: DateTime.now(),
      description: description,
    );

    final updated = [...timeline, newEvent];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$targetId',
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  /// Ensures a "Mission Created" event exists for the target.
  static Future<List<MissionTimelineEvent>> ensureCreatedEvent({
    required String targetId,
    required String targetName,
    DateTime? createdDate,
  }) async {
    final existing = await loadTimeline(targetId);
    if (existing.any((e) => e.type == MissionTimelineEventType.created)) {
      return existing;
    }

    final createdEvent = MissionTimelineEvent(
      id: '${targetId}_created',
      targetId: targetId,
      type: MissionTimelineEventType.created,
      timestamp: createdDate ?? DateTime.now(),
      description: 'Mission "$targetName" created.',
    );

    final updated = [createdEvent, ...existing];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$targetId',
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );

    return updated;
  }
}
