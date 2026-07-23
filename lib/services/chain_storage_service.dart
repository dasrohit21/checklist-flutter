import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mission_chain.dart';
import '../models/mission_chain_history.dart';
import '../models/mission_chain_statistics.dart';

class ChainStorageService {
  static const String _chainsKey = 'checklist_mission_chains';
  static const String _activeChainIdKey = 'checklist_active_chain_id';
  static const String _chainHistoryKey = 'checklist_mission_chain_history';
  static const String _chainStatsKey = 'checklist_mission_chain_stats';

  static Future<List<MissionChain>> loadChains() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chainsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(MissionChain.fromJson)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveChains(List<MissionChain> chains) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = chains.map((c) => c.toJson()).toList();
    await prefs.setString(_chainsKey, jsonEncode(jsonList));
  }

  static Future<String?> loadActiveChainId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeChainIdKey);
  }

  static Future<void> saveActiveChainId(String? chainId) async {
    final prefs = await SharedPreferences.getInstance();
    if (chainId == null) {
      await prefs.remove(_activeChainIdKey);
    } else {
      await prefs.setString(_activeChainIdKey, chainId);
    }
  }

  static Future<List<MissionChainHistory>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chainHistoryKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(MissionChainHistory.fromJson)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveHistory(List<MissionChainHistory> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_chainHistoryKey, jsonEncode(jsonList));
  }

  static Future<MissionChainStatistics> loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chainStatsKey);
    if (raw == null) return const MissionChainStatistics();
    try {
      return MissionChainStatistics.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      return const MissionChainStatistics();
    }
  }

  static Future<void> saveStatistics(MissionChainStatistics stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chainStatsKey, jsonEncode(stats.toJson()));
  }
}
