import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


import '../models/checklist_item.dart';
import '../models/target_item.dart';
import '../models/category_item.dart';
import '../models/mission.dart';
import '../models/mission_chain.dart';
import '../models/mission_chain_history.dart';
import '../models/mission_chain_statistics.dart';

import '../services/notification_service.dart';
import '../services/chain_storage_service.dart';
import '../services/chain_statistics_service.dart';
import '../services/mission_history_service.dart';
import '../models/mission_timeline_event.dart';
import '../models/mission_history_item.dart';
import '../models/achievement.dart';
import 'package:flutter/material.dart';




/// Sort order for the active-target list.
enum SortOption { newest, oldest, alphabetical, deadline, progress, priority }


class AppState extends ChangeNotifier {
  AppState();

  // ── SharedPreferences keys ─────────────────────────────────────────────────
  static const String _targetsKey       = 'targets';
  static const String _checklistKey     = 'checklist_items';
  static const String _archiveKey       = 'archived_targets';
  static const String _sortKey          = 'sort_option';
  static const String _streakCurrentKey = 'streak_current';
  static const String _streakBestKey    = 'streak_best';
  static const String _streakLastKey    = 'streak_last_date';
  static const String _activityKey      = 'daily_activity';
  static const String _categoriesKey    = 'categories';
  static const String _defaultCategoryKey = 'default_category_id';
  static const String _defaultCountKey  = 'default_target_count';
  static const String _animationsOnKey  = 'animations_on';
  static const String _activeMissionKey = 'active_mission';
  static const String _missionStatsKey  = 'mission_stats';

  static const String _totalXpKey = 'prod_total_xp';
  static const String _levelKey = 'prod_level';
  static const String _disciplineScoreKey = 'prod_discipline_score';
  static const String _longestSessionKey = 'prod_longest_session';
  static const String _missionHistoryKey = 'prod_mission_history';
  static const String _unlockedAchievementsKey = 'prod_unlocked_achievements';
  static const String _xpPopupsEnabledKey = 'prod_xp_popups_enabled';
  static const String _soundsEnabledKey = 'prod_sounds_enabled';
  static const String _notificationsEnabledKey = 'prod_notifications_enabled';
  static const String _defaultEstimatedDurationKey = 'prod_default_duration';
  static const String _missionStreakCurrentKey = 'prod_mission_streak_current';
  static const String _missionStreakBestKey = 'prod_mission_streak_best';
  static const String _missionStreakLastKey = 'prod_mission_streak_last_date';

  // ── State ──────────────────────────────────────────────────────────────────
  final List<ChecklistItem>       _checklistItems  = [];
  final List<TargetItem>          _targets         = [];
  final List<TargetItem>          _archivedTargets = [];
  final List<CategoryItem>        _categories      = [];
  
  SortOption                      _sortOption      = SortOption.newest;
  int                             _currentStreak   = 0;
  int                             _bestStreak      = 0;
  String?                         _lastActivityDate;
  final Map<String, List<String>> _dailyActivity   = {};

  // Settings
  String?                         _defaultCategoryId;
  int                             _defaultTargetCount = 5;
  bool                            _animationsOn      = true;

  Mission?                        _activeMission;
  MissionStatistics               _missionStats = MissionStatistics(
    totalMissionsStarted: 0,
    totalMissionsCompleted: 0,
    totalDurationSeconds: 0,
  );

  // Productivity State
  int                             _totalXp = 0;
  int                             _level = 1;
  int                             _disciplineScore = 75;
  int                             _longestSessionSeconds = 0;
  final List<MissionHistoryItem>  _missionHistory = [];
  final List<String>              _unlockedAchievementIds = [];
  bool                            _xpPopupsEnabled = true;
  bool                            _soundsEnabled = true;
  bool                            _notificationsEnabled = true;
  int                             _defaultEstimatedDurationMinutes = 60;
  int                             _missionStreakCurrent = 0;
  int                             _missionStreakBest = 0;
  String?                         _missionLastCompletionDate;

  // Mission Chains State
  final List<MissionChain>        _chains = [];
  MissionChain?                   _activeChain;
  final List<MissionChainHistory> _chainHistory = [];
  MissionChainStatistics          _chainStats = const MissionChainStatistics();
  MissionChain?                   _celebratingChain;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<ChecklistItem>          get checklistItems  => List.unmodifiable(_checklistItems);
  List<TargetItem>             get targets         => List.unmodifiable(_targets);
  List<TargetItem>             get archivedTargets => List.unmodifiable(_archivedTargets);
  List<CategoryItem>           get categories      => List.unmodifiable(_categories);
  SortOption                   get sortOption      => _sortOption;
  int                          get currentStreak   => _currentStreak;
  int                          get bestStreak      => _bestStreak;
  Map<String, List<String>>    get dailyActivity   => Map.unmodifiable(_dailyActivity);

  String?                      get defaultCategoryId => _defaultCategoryId;
  int                          get defaultTargetCount => _defaultTargetCount;
  bool                         get animationsOn      => _animationsOn;
  Mission?                     get activeMission     => _activeMission;
  MissionStatistics            get missionStats      => _missionStats;

  int                          get totalXp => _totalXp;
  int                          get level => _level;
  int                          get disciplineScore => _disciplineScore;
  int                          get longestSessionSeconds => _longestSessionSeconds;
  List<MissionHistoryItem>     get missionHistory => List.unmodifiable(_missionHistory);
  List<String>                 get unlockedAchievementIds => List.unmodifiable(_unlockedAchievementIds);
  bool                         get xpPopupsEnabled => _xpPopupsEnabled;
  bool                         get soundsEnabled => _soundsEnabled;
  bool                         get notificationsEnabled => _notificationsEnabled;
  int                          get defaultEstimatedDurationMinutes => _defaultEstimatedDurationMinutes;
  int                          get missionStreakCurrent => _missionStreakCurrent;
  int                          get missionStreakBest => _missionStreakBest;
  String?                      get missionLastCompletionDate => _missionLastCompletionDate;

  List<MissionChain>           get chains => List.unmodifiable(_chains);
  MissionChain?                get activeChain => _activeChain;
  List<MissionChainHistory>    get chainHistory => List.unmodifiable(_chainHistory);
  MissionChainStatistics       get chainStats => _chainStats;
  MissionChain?                get celebratingChain => _celebratingChain;


  final List<Achievement> achievementsList = [
    Achievement(
      id: 'first_mission',
      title: 'First Step',
      description: 'Complete your first focus mission.',
      icon: Icons.check_circle_outline_rounded,
    ),
    Achievement(
      id: '10_missions',
      title: 'Decathlon Focus',
      description: 'Complete 10 focus missions.',
      icon: Icons.stars_rounded,
    ),
    Achievement(
      id: '100_missions',
      title: 'Centurion of Focus',
      description: 'Complete 100 focus missions.',
      icon: Icons.emoji_events_rounded,
    ),
    Achievement(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Complete at least one mission every day for 7 consecutive days.',
      icon: Icons.date_range_rounded,
    ),
    Achievement(
      id: '30_day_streak',
      title: 'Unstoppable Streak',
      description: 'Achieve a 30-day focus mission streak.',
      icon: Icons.local_fire_department_rounded,
    ),
    Achievement(
      id: '100_hours',
      title: 'Deep Work Master',
      description: 'Accumulate 100 hours of active mission focus.',
      icon: Icons.timer_rounded,
    ),
  ];

  List<Achievement> get achievements {
    return achievementsList.map((a) {
      final isUnlocked = _unlockedAchievementIds.contains(a.id);
      return a.copyWith(isUnlocked: isUnlocked);
    }).toList();
  }



  // ── Statistics ─────────────────────────────────────────────────────────────
  int get totalTargets =>
      _targets.length + _archivedTargets.length;

  int get activeTargetsCount =>
      _targets.where((t) => t.solvedCount < t.targetCount).length;

  int get completedTargetsCount =>
      _targets.where((t) => t.targetCount > 0 && t.solvedCount >= t.targetCount).length +
      _archivedTargets.where((t) => t.targetCount > 0 && t.solvedCount >= t.targetCount).length;

  double get completionRate =>
      totalTargets == 0 ? 0.0 : completedTargetsCount / totalTargets;

  int get totalProblemsSolved =>
      [..._targets, ..._archivedTargets].fold(0, (s, t) => s + t.solvedCount);

  int get problemsRemaining =>
      _targets.fold(0, (s, t) =>
          s + (t.targetCount - t.solvedCount).clamp(0, t.targetCount));

  // ── Sorted active targets ──────────────────────────────────────────────────
  List<TargetItem> get sortedTargets {
    final list = [..._targets];
    switch (_sortOption) {
      case SortOption.newest:
        list.sort((a, b) => b.id.compareTo(a.id));
      case SortOption.oldest:
        list.sort((a, b) => a.id.compareTo(b.id));
      case SortOption.alphabetical:
        list.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SortOption.deadline:
        list.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case SortOption.progress:
        list.sort((a, b) {
          final aP = a.targetCount == 0 ? 0.0 : a.solvedCount / a.targetCount;
          final bP = b.targetCount == 0 ? 0.0 : b.solvedCount / b.targetCount;
          return bP.compareTo(aP); // highest progress first
        });
      case SortOption.priority:
        final priorityValue = {'high': 3, 'medium': 2, 'low': 1};
        list.sort((a, b) {
          final valA = priorityValue[a.priority] ?? 2;
          final valB = priorityValue[b.priority] ?? 2;
          return valB.compareTo(valA); // High priority first
        });
    }
    return list;
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Default settings
    _defaultCategoryId = prefs.getString(_defaultCategoryKey);
    _defaultTargetCount = prefs.getInt(_defaultCountKey) ?? 5;
    _animationsOn = prefs.getBool(_animationsOnKey) ?? true;

    // Load categories
    final rawCategories = prefs.getString(_categoriesKey);
    if (rawCategories != null) {
      final decoded = jsonDecode(rawCategories) as List<dynamic>;
      _categories
        ..clear()
        ..addAll(decoded.whereType<Map<String, dynamic>>().map(CategoryItem.fromJson));
      
      final defaultIds = {'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8'};
      if (_categories.any((c) => defaultIds.contains(c.id))) {
        _categories.removeWhere((c) => defaultIds.contains(c.id));
        await _saveCategories();
      }
    } else {
      _categories.clear();
      await _saveCategories();
    }



    // Targets
    final rawTargets = prefs.getString(_targetsKey);
    if (rawTargets != null) {
      final decoded = jsonDecode(rawTargets) as List<dynamic>;
      _targets
        ..clear()
        ..addAll(decoded.whereType<Map<String, dynamic>>().map(TargetItem.fromJson));
    }

    // Checklist
    final rawChecklist = prefs.getString(_checklistKey);
    if (rawChecklist != null) {
      final decoded = jsonDecode(rawChecklist) as List<dynamic>;
      _checklistItems
        ..clear()
        ..addAll(decoded.whereType<Map<String, dynamic>>().map(ChecklistItem.fromJson));
    }

    // Archive
    final rawArchive = prefs.getString(_archiveKey);
    if (rawArchive != null) {
      final decoded = jsonDecode(rawArchive) as List<dynamic>;
      _archivedTargets
        ..clear()
        ..addAll(decoded.whereType<Map<String, dynamic>>().map(TargetItem.fromJson));
    }

    // Sort option
    final rawSort = prefs.getString(_sortKey);
    if (rawSort != null) {
      _sortOption = SortOption.values.firstWhere(
        (e) => e.name == rawSort,
        orElse: () => SortOption.newest,
      );
    }

    // Streak
    _currentStreak    = prefs.getInt(_streakCurrentKey) ?? 0;
    _bestStreak       = prefs.getInt(_streakBestKey) ?? 0;
    _lastActivityDate = prefs.getString(_streakLastKey);

    // Break streak if no activity since before yesterday
    if (_lastActivityDate != null) {
      final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
      final today     = _todayString();
      if (_lastActivityDate != today && _lastActivityDate != yesterday) {
        _currentStreak = 0;
        await _saveStreak();
      }
    }

    // Daily activity
    final rawActivity = prefs.getString(_activityKey);
    if (rawActivity != null) {
      final decoded = jsonDecode(rawActivity) as Map<String, dynamic>;
      _dailyActivity.clear();
      for (final entry in decoded.entries) {
        _dailyActivity[entry.key] = (entry.value as List<dynamic>).cast<String>();
      }
    }
    // Active Mission

    final rawActiveMission = prefs.getString(_activeMissionKey);
    if (rawActiveMission != null) {
      _activeMission = Mission.fromJson(jsonDecode(rawActiveMission) as Map<String, dynamic>);
    } else {
      _activeMission = null;
    }

    // Mission Statistics
    final rawMissionStats = prefs.getString(_missionStatsKey);
    if (rawMissionStats != null) {
      _missionStats = MissionStatistics.fromJson(jsonDecode(rawMissionStats) as Map<String, dynamic>);
    } else {
      _missionStats = MissionStatistics(
        totalMissionsStarted: 0,
        totalMissionsCompleted: 0,
        totalDurationSeconds: 0,
      );
    }

    _totalXp = prefs.getInt(_totalXpKey) ?? 0;
    _level = prefs.getInt(_levelKey) ?? 1;
    _disciplineScore = prefs.getInt(_disciplineScoreKey) ?? 75;
    _longestSessionSeconds = prefs.getInt(_longestSessionKey) ?? 0;
    _xpPopupsEnabled = prefs.getBool(_xpPopupsEnabledKey) ?? true;
    _soundsEnabled = prefs.getBool(_soundsEnabledKey) ?? true;
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    _defaultEstimatedDurationMinutes = prefs.getInt(_defaultEstimatedDurationKey) ?? 60;
    _missionStreakCurrent = prefs.getInt(_missionStreakCurrentKey) ?? 0;
    _missionStreakBest = prefs.getInt(_missionStreakBestKey) ?? 0;
    _missionLastCompletionDate = prefs.getString(_missionStreakLastKey);

    final rawHistory = prefs.getString(_missionHistoryKey);
    if (rawHistory != null) {
      final decoded = jsonDecode(rawHistory) as List<dynamic>;
      _missionHistory.clear();
      _missionHistory.addAll(decoded.whereType<Map<String, dynamic>>().map(MissionHistoryItem.fromJson));
    }

    final rawAchievementIds = prefs.getString(_unlockedAchievementsKey);
    if (rawAchievementIds != null) {
      final decoded = jsonDecode(rawAchievementIds) as List<dynamic>;
      _unlockedAchievementIds.clear();
      _unlockedAchievementIds.addAll(decoded.cast<String>());
    }

    if (_missionLastCompletionDate != null) {
      final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
      final today = _todayString();
      if (_missionLastCompletionDate != today && _missionLastCompletionDate != yesterday) {
        _missionStreakCurrent = 0;
        await prefs.setInt(_missionStreakCurrentKey, 0);
      }
    }

    await _loadChainsData();

    debugPrint('[AppState.load] targets=${_targets.length}, '
        'checklist=${_checklistItems.length}, '
        'archived=${_archivedTargets.length}, '
        'categories=${_categories.length}, '
        'streak=$_currentStreak, xp=$_totalXp, level=$_level, chains=${_chains.length}');



    // Trigger reminders on load
    final incompleteCount = _targets.where((t) => t.solvedCount < t.targetCount).length;
    final solvedCountToday = _dailyActivity[_todayString()]?.length ?? 0;
    final upcomingList = _targets.where((t) => t.dueDate != null && t.solvedCount < t.targetCount).toList();
    NotificationService.checkAndNotify(
      activeTargetsIncomplete: incompleteCount,
      streak: _currentStreak,
      problemsSolvedToday: solvedCountToday,
      upcomingDeadlines: upcomingList,
    );

    notifyListeners();
  }



  // ── Settings mutations ─────────────────────────────────────────────────────
  Future<void> setDefaultCategoryId(String? id) async {
    _defaultCategoryId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_defaultCategoryKey);
    } else {
      await prefs.setString(_defaultCategoryKey, id);
    }
    notifyListeners();
  }

  Future<void> setDefaultTargetCount(int count) async {
    _defaultTargetCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultCountKey, count);
    notifyListeners();
  }

  Future<void> setAnimationsOn(bool on) async {
    _animationsOn = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_animationsOnKey, on);
    notifyListeners();
  }

  // ── Category mutations ─────────────────────────────────────────────────────
  Future<void> addCategory(String name, int colorValue) async {
    if (name.trim().isEmpty) return;
    final category = CategoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      colorValue: colorValue,
    );
    _categories.add(category);
    await _saveCategories();
    notifyListeners();
  }

  Future<void> updateCategory(String id, String name, int colorValue) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    _categories[index] = _categories[index].copyWith(name: name.trim(), colorValue: colorValue);
    await _saveCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    if (_defaultCategoryId == id) {
      _defaultCategoryId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_defaultCategoryKey);
    }
    // Clean up category assignments in targets
    for (var i = 0; i < _targets.length; i++) {
      if (_targets[i].categoryId == id) {
        _targets[i] = _targets[i].copyWith(categoryId: null);
      }
    }
    for (var i = 0; i < _archivedTargets.length; i++) {
      if (_archivedTargets[i].categoryId == id) {
        _archivedTargets[i] = _archivedTargets[i].copyWith(categoryId: null);
      }
    }
    await _saveCategories();
    await _saveTargets();
    await _saveArchive();
    notifyListeners();
  }

  // ── Sort option ────────────────────────────────────────────────────────────
  Future<void> setSortOption(SortOption option) async {
    if (_sortOption == option) return;
    _sortOption = option;
    await _saveSort();
    notifyListeners();
  }

  // ── Checklist mutations ────────────────────────────────────────────────────
  Future<void> addChecklistItem(String text, String type) async {
    if (text.trim().isEmpty) return;
    final item = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      type: type,
    );
    _checklistItems.add(item);
    await _saveChecklist();
    notifyListeners();
  }

  Future<void> updateChecklistItem(String id, String text) async {
    final index = _checklistItems.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _checklistItems[index] = _checklistItems[index].copyWith(text: text.trim());
    await _saveChecklist();
    notifyListeners();
  }

  Future<void> deleteChecklistItem(String id) async {
    _checklistItems.removeWhere((item) => item.id == id);
    await _saveChecklist();
    notifyListeners();
  }

  Future<void> toggleChecklistItem(String id) async {
    final index = _checklistItems.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _checklistItems[index] = _checklistItems[index].copyWith(
      completed: !_checklistItems[index].completed,
    );
    await _saveChecklist();
    notifyListeners();
  }

  Future<void> reorderChecklistItems(int oldIndex, int newIndex, String type) async {
    final typeItems = _checklistItems.where((item) => item.type == type).toList();
    if (oldIndex < 0 || oldIndex >= typeItems.length) return;
    if (newIndex < 0 || newIndex > typeItems.length) return;
    if (oldIndex < newIndex) newIndex -= 1;

    final item = typeItems.removeAt(oldIndex);
    typeItems.insert(newIndex, item);

    // Reconstruct full list keeping order
    final otherItems = _checklistItems.where((i) => i.type != type).toList();
    _checklistItems.clear();
    _checklistItems.addAll(typeItems);
    _checklistItems.addAll(otherItems);

    await _saveChecklist();
    notifyListeners();
  }

  // ── Target mutations ───────────────────────────────────────────────────────
  Future<void> addTarget(
    String title,
    int count, {
    DateTime? dueDate,
    String priority = 'medium',
    String notes = '',
    List<String> tags = const [],
    String? categoryId,
    List<TargetLink> links = const [],
  }) async {
    if (title.trim().isEmpty || count < 1) return;
    final item = TargetItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      targetCount: count,
      dueDate: _dateOnly(dueDate),
      priority: priority,
      notes: notes,
      tags: tags,
      categoryId: categoryId,
      links: links,
    );
    _targets.add(item);
    await _saveTargets();
    await MissionHistoryService.recordEvent(
      targetId: item.id,
      type: MissionTimelineEventType.created,
      description: 'Mission "${item.title}" created.',
    );
    notifyListeners();
  }

  Future<void> updateTarget(
    String id,
    String title,
    int count, {
    DateTime? dueDate,
    String priority = 'medium',
    String notes = '',
    List<String> tags = const [],
    String? categoryId,
    List<TargetLink> links = const [],
  }) async {
    final index = _targets.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current   = _targets[index];
    final nextCount = count < 1 ? current.targetCount : count;
    final nextSolved =
        current.solvedCount > nextCount ? nextCount : current.solvedCount;
    _targets[index] = current.copyWith(
      title: title.trim(),
      targetCount: nextCount,
      solvedCount: nextSolved,
      dueDate: _dateOnly(dueDate),
      priority: priority,
      notes: notes,
      tags: tags,
      categoryId: categoryId,
      links: links,
    );
    await _saveTargets();
    notifyListeners();
  }

  Future<void> deleteTarget(String id) async {
    _targets.removeWhere((item) => item.id == id);
    await _saveTargets();
    notifyListeners();
  }

  Future<void> setSolved(String id, int solved) async {
    final index = _targets.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current     = _targets[index];
    final nextSolved  = solved.clamp(0, current.targetCount);
    final didProgress = nextSolved > current.solvedCount;
    _targets[index]   = current.copyWith(solvedCount: nextSolved);
    if (didProgress) {
      _updateStreak();
      _recordTargetActivity(id);
    }
    await _saveTargets();
    if (didProgress) {
      await _saveStreak();
      await _saveActivity();
    }
    if (_activeMission != null && _activeMission!.targetId == id) {
      _activeMission = _activeMission!.copyWith(
        solvedCount: nextSolved,
      );
      if (nextSolved >= current.targetCount) {
        final now = DateTime.now();
        final finalAccumulated = _activeMission!.accumulatedSeconds +
            (_activeMission!.isPaused || _activeMission!.lastResumeTime == null
                ? 0
                : now.difference(_activeMission!.lastResumeTime!).inSeconds);

        // 1. Focus Score Calculation
        int focusScore = (100 - (_activeMission!.interruptionCount * 15)).clamp(0, 100);
        final estimatedSeconds = _activeMission!.estimatedDurationMinutes * 60;
        if (finalAccumulated <= estimatedSeconds) {
          focusScore += 10;
        } else {
          final overtimeMinutes = ((finalAccumulated - estimatedSeconds) / 60).round();
          focusScore -= overtimeMinutes;
        }
        focusScore = focusScore.clamp(0, 100);

        // 2. Discipline Score Adjustments (+5 on complete, -2 per interruption)
        _disciplineScore = (_disciplineScore + 5 - (_activeMission!.interruptionCount * 2)).clamp(0, 100);

        // 3. XP Calculation
        int xpEarned = 100; // Base Complete
        final solvedDuringMission = (nextSolved - _activeMission!.startSolvedCount).clamp(0, current.targetCount);
        final targetsRemainingAtStart = current.targetCount - _activeMission!.startSolvedCount;
        final isPerfect = _activeMission!.interruptionCount == 0 && solvedDuringMission >= targetsRemainingAtStart;
        if (isPerfect) {
          xpEarned += 50; // Perfect mission
        }
        if (_activeMission!.interruptionCount == 0) {
          xpEarned += 25; // No interruptions
        }
        if (finalAccumulated <= estimatedSeconds) {
          xpEarned += 25; // Early completion
        }
        if (_missionStreakCurrent > 0) {
          xpEarned += 20; // Daily Streak
        }

        // 4. Streak Calculation
        final todayStr = _todayString();
        final yesterdayStr = _dateString(now.subtract(const Duration(days: 1)));
        if (_missionLastCompletionDate == null) {
          _missionStreakCurrent = 1;
        } else if (_missionLastCompletionDate == yesterdayStr) {
          _missionStreakCurrent += 1;
        } else if (_missionLastCompletionDate != todayStr) {
          _missionStreakCurrent = 1;
        }
        _missionLastCompletionDate = todayStr;
        if (_missionStreakCurrent > _missionStreakBest) {
          _missionStreakBest = _missionStreakCurrent;
        }

        // 5. XP & Level Up calculation
        _totalXp += xpEarned;
        int xpNeeded = _level * 1000;
        while (_totalXp >= xpNeeded) {
          _level += 1;
          xpNeeded = _level * 1000;
        }

        // 6. Longest Session
        if (finalAccumulated > _longestSessionSeconds) {
          _longestSessionSeconds = finalAccumulated;
        }

        // 7. Append to History
        final historyItem = MissionHistoryItem(
          id: _activeMission!.id,
          name: _activeMission!.name,
          type: _activeMission!.type,
          startTime: _activeMission!.startTime,
          endTime: now,
          durationSeconds: finalAccumulated,
          problemsSolved: solvedDuringMission,
          interruptions: _activeMission!.interruptionCount,
          status: 'completed',
          xpEarned: xpEarned,
          focusScore: focusScore,
        );
        _missionHistory.add(historyItem);

        // 8. Achievements Check
        _checkAchievements();


        // 9. Save Productivity Data
        await _saveProductivityData();

        _activeMission = _activeMission!.copyWith(
          status: MissionStatus.completed,
          endTime: now,
          accumulatedSeconds: finalAccumulated,
          lastResumeTime: null,
          isPaused: true,
        );
        
        _missionStats = _missionStats.copyWith(
          totalMissionsCompleted: _missionStats.totalMissionsCompleted + 1,
          totalDurationSeconds: _missionStats.totalDurationSeconds + finalAccumulated,
        );
        await _saveMissionStats();

        if (_activeChain != null) {
          await _handleChainMissionCompletion();
        }

        await _saveActiveMission();
        await MissionHistoryService.recordEvent(
          targetId: current.id,
          type: MissionTimelineEventType.completed,
          description: 'Mission "${current.title}" completed!',
        );
      }
    }

    notifyListeners();
  }

  Future<void> startMission(String targetId, String name, int estimatedDurationMinutes, MissionType type) async {
    final target = _targets.firstWhere((t) => t.id == targetId);
    final now = DateTime.now();
    _activeMission = Mission(
      id: now.millisecondsSinceEpoch.toString(),
      targetId: targetId,
      name: name.trim().isEmpty ? 'Mission: ${target.title}' : name.trim(),
      targetCount: target.targetCount,
      startSolvedCount: target.solvedCount,
      solvedCount: target.solvedCount,
      startTime: now,
      estimatedDurationMinutes: estimatedDurationMinutes,
      type: type,
      status: MissionStatus.active,
      isPaused: false,
      accumulatedSeconds: 0,
      lastResumeTime: now,
      interruptionCount: 0,
    );
    _missionStats = _missionStats.copyWith(
      totalMissionsStarted: _missionStats.totalMissionsStarted + 1,
    );
    await _saveActiveMission();
    await _saveMissionStats();
    await MissionHistoryService.recordEvent(
      targetId: targetId,
      type: MissionTimelineEventType.started,
      description: 'Mission started.',
    );
    notifyListeners();
  }

  Future<void> pauseActiveMission() async {
    if (_activeMission == null || _activeMission!.isPaused) return;
    final now = DateTime.now();
    final elapsedSegment = _activeMission!.lastResumeTime == null
        ? 0
        : now.difference(_activeMission!.lastResumeTime!).inSeconds;
    
    _activeMission = _activeMission!.copyWith(
      isPaused: true,
      accumulatedSeconds: _activeMission!.accumulatedSeconds + elapsedSegment,
      lastResumeTime: null,
      interruptionCount: _activeMission!.interruptionCount + 1,
    );
    await _saveActiveMission();
    await MissionHistoryService.recordEvent(
      targetId: _activeMission!.targetId,
      type: MissionTimelineEventType.paused,
      description: 'Mission paused.',
    );
    notifyListeners();
  }

  Future<void> resumeActiveMission() async {
    if (_activeMission == null || !_activeMission!.isPaused) return;
    _activeMission = _activeMission!.copyWith(
      isPaused: false,
      lastResumeTime: DateTime.now(),
    );
    await _saveActiveMission();
    await MissionHistoryService.recordEvent(
      targetId: _activeMission!.targetId,
      type: MissionTimelineEventType.resumed,
      description: 'Mission resumed.',
    );
    notifyListeners();
  }

  Future<void> recordInterruption() async {
    if (_activeMission == null) return;
    _activeMission = _activeMission!.copyWith(
      interruptionCount: _activeMission!.interruptionCount + 1,
    );
    _disciplineScore = (_disciplineScore - 2).clamp(0, 100);
    await _saveActiveMission();
    await _saveProductivityData();
    notifyListeners();
  }

  Future<void> clearActiveMission() async {
    if (_activeMission != null && _activeMission!.status == MissionStatus.active) {
      final now = DateTime.now();
      final finalAccumulated = _activeMission!.accumulatedSeconds +
          (_activeMission!.isPaused || _activeMission!.lastResumeTime == null
              ? 0
              : now.difference(_activeMission!.lastResumeTime!).inSeconds);

      _disciplineScore = (_disciplineScore - 15).clamp(0, 100);

      final historyItem = MissionHistoryItem(
        id: _activeMission!.id,
        name: _activeMission!.name,
        type: _activeMission!.type,
        startTime: _activeMission!.startTime,
        endTime: now,
        durationSeconds: finalAccumulated,
        problemsSolved: (_activeMission!.solvedCount - _activeMission!.startSolvedCount).clamp(0, _activeMission!.targetCount),
        interruptions: _activeMission!.interruptionCount,
        status: 'abandoned',
        xpEarned: 0,
        focusScore: 0,
      );
      _missionHistory.add(historyItem);
      _checkAchievements();
      await _saveProductivityData();
    }
    _activeMission = null;
    await _saveActiveMission();
    notifyListeners();
  }

  Future<void> setXpPopupsEnabled(bool enabled) async {
    _xpPopupsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_xpPopupsEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setSoundsEnabled(bool enabled) async {
    _soundsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundsEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setDefaultEstimatedDurationMinutes(int minutes) async {
    _defaultEstimatedDurationMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultEstimatedDurationKey, minutes);
    notifyListeners();
  }

  void _checkAchievements() {
    final completedCount = _missionHistory.where((m) => m.status == 'completed').length;
    if (completedCount >= 1) {
      _unlockAchievement('first_mission');
    }
    if (completedCount >= 10) {
      _unlockAchievement('10_missions');
    }
    if (completedCount >= 100) {
      _unlockAchievement('100_missions');
    }
    if (_missionStreakBest >= 7) {
      _unlockAchievement('perfect_week');
    }
    if (_missionStreakBest >= 30) {
      _unlockAchievement('30_day_streak');
    }
    final totalSeconds = _missionHistory.where((m) => m.status == 'completed').fold(0, (s, m) => s + m.durationSeconds);
    final totalHours = totalSeconds / 3600;
    if (totalHours >= 100) {
      _unlockAchievement('100_hours');
    }
  }

  void _unlockAchievement(String id) {
    if (!_unlockedAchievementIds.contains(id)) {
      _unlockedAchievementIds.add(id);
      if (_notificationsEnabled) {
        final ach = achievementsList.firstWhere((a) => a.id == id);
        NotificationService.showNotification(
          id: id.hashCode,
          title: 'Achievement Unlocked! 🏆',
          body: '${ach.title}: ${ach.description}',
        );
      }
    }
  }

  Future<void> _saveProductivityData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalXpKey, _totalXp);
    await prefs.setInt(_levelKey, _level);
    await prefs.setInt(_disciplineScoreKey, _disciplineScore);
    await prefs.setInt(_longestSessionKey, _longestSessionSeconds);
    await prefs.setString(_missionHistoryKey, jsonEncode(_missionHistory.map((e) => e.toJson()).toList()));
    await prefs.setString(_unlockedAchievementsKey, jsonEncode(_unlockedAchievementIds));
    await prefs.setInt(_missionStreakCurrentKey, _missionStreakCurrent);
    await prefs.setInt(_missionStreakBestKey, _missionStreakBest);
    if (_missionLastCompletionDate != null) {
      await prefs.setString(_missionStreakLastKey, _missionLastCompletionDate!);
    }
  }

  // ── Mission Chains Methods ───────────────────────────────────────────────

  Future<void> _loadChainsData() async {
    _chains.clear();
    _chains.addAll(await ChainStorageService.loadChains());
    _chainHistory.clear();
    _chainHistory.addAll(await ChainStorageService.loadHistory());
    _chainStats = await ChainStorageService.loadStatistics();
    
    final activeId = await ChainStorageService.loadActiveChainId();
    if (activeId != null) {
      final index = _chains.indexWhere((c) => c.id == activeId);
      if (index != -1 && _chains[index].status == ChainStatus.active) {
        _activeChain = _chains[index];
      }
    }
  }

  Future<void> addChain(MissionChain chain) async {
    _chains.add(chain);
    await ChainStorageService.saveChains(_chains);
    notifyListeners();
  }

  Future<void> updateChain(MissionChain chain) async {
    final index = _chains.indexWhere((c) => c.id == chain.id);
    if (index != -1) {
      _chains[index] = chain;
      if (_activeChain?.id == chain.id) {
        _activeChain = chain;
      }
      await ChainStorageService.saveChains(_chains);
      notifyListeners();
    }
  }

  Future<void> deleteChain(String id) async {
    _chains.removeWhere((c) => c.id == id);
    if (_activeChain?.id == id) {
      _activeChain = null;
      await ChainStorageService.saveActiveChainId(null);
    }
    await ChainStorageService.saveChains(_chains);
    notifyListeners();
  }

  Future<void> reorderChainItems(String chainId, int oldIndex, int newIndex) async {
    final chainIndex = _chains.indexWhere((c) => c.id == chainId);
    if (chainIndex == -1) return;
    final chain = _chains[chainIndex];
    final items = List<MissionChainItem>.from(chain.items);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    final updatedItems = items.asMap().entries.map((e) => e.value.copyWith(order: e.key)).toList();
    final updatedChain = chain.copyWith(items: updatedItems);
    _chains[chainIndex] = updatedChain;
    if (_activeChain?.id == chainId) {
      _activeChain = updatedChain;
    }
    await ChainStorageService.saveChains(_chains);
    notifyListeners();
  }

  Future<void> startChain(String chainId) async {
    final index = _chains.indexWhere((c) => c.id == chainId);
    if (index == -1) return;

    final now = DateTime.now();
    final originalChain = _chains[index];

    final preparedItems = originalChain.items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      return item.copyWith(
        isCompleted: false,
        isLocked: idx != 0,
      );
    }).toList();

    final startedChain = originalChain.copyWith(
      items: preparedItems,
      currentMissionIndex: 0,
      status: ChainStatus.active,
      startTime: now,
      endTime: null,
    );

    _chains[index] = startedChain;
    _activeChain = startedChain;

    await ChainStorageService.saveChains(_chains);
    await ChainStorageService.saveActiveChainId(startedChain.id);

    if (preparedItems.isNotEmpty) {
      final firstItem = preparedItems.first;
      await startMission(
        firstItem.targetId,
        firstItem.name,
        firstItem.estimatedDurationMinutes,
        firstItem.type,
      );
    }
    notifyListeners();
  }

  Future<void> pauseActiveChain() async {
    if (_activeChain == null) return;
    await pauseActiveMission();
    _activeChain = _activeChain!.copyWith(status: ChainStatus.paused);
    final index = _chains.indexWhere((c) => c.id == _activeChain!.id);
    if (index != -1) {
      _chains[index] = _activeChain!;
    }
    await ChainStorageService.saveChains(_chains);
    notifyListeners();
  }

  Future<void> resumeActiveChain() async {
    if (_activeChain == null) return;
    await resumeActiveMission();
    _activeChain = _activeChain!.copyWith(status: ChainStatus.active);
    final index = _chains.indexWhere((c) => c.id == _activeChain!.id);
    if (index != -1) {
      _chains[index] = _activeChain!;
    }
    await ChainStorageService.saveChains(_chains);
    notifyListeners();
  }

  Future<void> abandonActiveChain() async {
    if (_activeChain == null) return;
    final chain = _activeChain!;
    final now = DateTime.now();
    final durationSeconds = chain.startTime != null ? now.difference(chain.startTime!).inSeconds : 0;

    final updatedItems = List<MissionChainItem>.from(chain.items);
    final completedCount = updatedItems.where((i) => i.isCompleted).length;
    final remainingCount = updatedItems.length - completedCount;

    final failedChain = chain.copyWith(
      status: ChainStatus.abandoned,
      endTime: now,
    );

    final chainListIndex = _chains.indexWhere((c) => c.id == chain.id);
    if (chainListIndex != -1) {
      _chains[chainListIndex] = failedChain;
    }

    _disciplineScore = (_disciplineScore - 15).clamp(0, 100);

    final historyEntry = MissionChainHistory(
      id: now.millisecondsSinceEpoch.toString(),
      chainId: chain.id,
      chainName: chain.name,
      date: now,
      completionPercentage: chain.completionPercentage,
      durationSeconds: durationSeconds,
      completedMissions: completedCount,
      skippedMissions: remainingCount,
      interruptions: 0,
      xpEarned: 0,
      status: 'abandoned',
    );
    _chainHistory.add(historyEntry);

    _chainStats = ChainStatisticsService.recalculateStatistics(
      history: _chainHistory,
      chains: _chains,
    );

    _activeChain = null;
    _activeMission = null;
    await _saveActiveMission();

    await ChainStorageService.saveChains(_chains);
    await ChainStorageService.saveHistory(_chainHistory);
    await ChainStorageService.saveStatistics(_chainStats);
    await ChainStorageService.saveActiveChainId(null);
    await _saveProductivityData();

    notifyListeners();
  }

  Future<void> _handleChainMissionCompletion() async {
    if (_activeChain == null) return;

    final chain = _activeChain!;
    final currIdx = chain.currentMissionIndex;
    final updatedItems = List<MissionChainItem>.from(chain.items);
    updatedItems[currIdx] = updatedItems[currIdx].copyWith(isCompleted: true, isLocked: false);

    if (currIdx + 1 < updatedItems.length) {
      final nextIdx = currIdx + 1;
      updatedItems[nextIdx] = updatedItems[nextIdx].copyWith(isLocked: false);

      _activeChain = chain.copyWith(
        items: updatedItems,
        currentMissionIndex: nextIdx,
        status: ChainStatus.active,
      );

      final chainListIndex = _chains.indexWhere((c) => c.id == chain.id);
      if (chainListIndex != -1) {
        _chains[chainListIndex] = _activeChain!;
      }

      await ChainStorageService.saveChains(_chains);
      await ChainStorageService.saveActiveChainId(_activeChain!.id);

      final nextItem = updatedItems[nextIdx];

      await startMission(
        nextItem.targetId,
        nextItem.name,
        nextItem.estimatedDurationMinutes,
        nextItem.type,
      );

      if (_notificationsEnabled) {
        await NotificationService.showNotification(
          id: 200,
          title: 'Mission Complete! 🎯',
          body: 'Next Mission Ready: ${nextItem.name}. Tap to continue!',
        );
      }
    } else {
      final now = DateTime.now();
      final durationSeconds = chain.startTime != null ? now.difference(chain.startTime!).inSeconds : 0;
      final todayStr = _todayString();

      final newStreak = chain.currentStreak + 1;
      final newBestStreak = newStreak > chain.bestStreak ? newStreak : chain.bestStreak;

      final completedChain = chain.copyWith(
        items: updatedItems,
        status: ChainStatus.completed,
        endTime: now,
        currentStreak: newStreak,
        bestStreak: newBestStreak,
        lastCompletionDate: todayStr,
      );

      final chainListIndex = _chains.indexWhere((c) => c.id == chain.id);
      if (chainListIndex != -1) {
        _chains[chainListIndex] = completedChain;
      }

      _totalXp += 300;
      int xpNeeded = _level * 1000;
      while (_totalXp >= xpNeeded) {
        _level += 1;
        xpNeeded = _level * 1000;
      }
      _disciplineScore = (_disciplineScore + 10).clamp(0, 100);

      final historyEntry = MissionChainHistory(
        id: now.millisecondsSinceEpoch.toString(),
        chainId: chain.id,
        chainName: chain.name,
        date: now,
        completionPercentage: 1.0,
        durationSeconds: durationSeconds,
        completedMissions: updatedItems.length,
        skippedMissions: 0,
        interruptions: 0,
        xpEarned: chain.xpReward,
        status: 'completed',
      );
      _chainHistory.add(historyEntry);

      _chainStats = ChainStatisticsService.recalculateStatistics(
        history: _chainHistory,
        chains: _chains,
      );

      await ChainStorageService.saveChains(_chains);
      await ChainStorageService.saveHistory(_chainHistory);
      await ChainStorageService.saveStatistics(_chainStats);
      await ChainStorageService.saveActiveChainId(null);
      await _saveProductivityData();

      if (_notificationsEnabled) {
        await NotificationService.showNotification(
          id: 201,
          title: 'Chain Completed! 🎉',
          body: 'Congratulations! You completed ${chain.name} and earned +300 Bonus XP!',
        );
      }

      _celebratingChain = completedChain;
      _activeChain = null;
    }
  }

  void clearCelebratingChain() {
    _celebratingChain = null;
    notifyListeners();
  }

  Future<void> resetTarget(String id) async {
    final index = _targets.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _targets[index] = _targets[index].copyWith(solvedCount: 0);
    await _saveTargets();
    if (_activeMission != null && _activeMission!.targetId == id) {
      _activeMission = _activeMission!.copyWith(solvedCount: 0);
      await _saveActiveMission();
    }
    notifyListeners();
  }

  Future<void> resetAllTargets() async {
    for (var i = 0; i < _targets.length; i++) {
      _targets[i] = _targets[i].copyWith(solvedCount: 0);
    }
    await _saveTargets();
    if (_activeMission != null) {
      _activeMission = _activeMission!.copyWith(solvedCount: 0);
      await _saveActiveMission();
    }
    notifyListeners();
  }


  Future<void> incrementTarget(String id) async {
    final index = _targets.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = _targets[index];
    _targets[index] = current.copyWith(targetCount: current.targetCount + 1);
    await _saveTargets();
    notifyListeners();
  }

  Future<void> decrementTarget(String id) async {
    final index = _targets.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = _targets[index];
    if (current.targetCount <= 1) return;
    final nextCount  = current.targetCount - 1;
    final nextSolved =
        current.solvedCount > nextCount ? nextCount : current.solvedCount;
    _targets[index] = current.copyWith(
      targetCount: nextCount,
      solvedCount: nextSolved,
    );
    await _saveTargets();
    notifyListeners();
  }

  Future<void> focusTarget(String id) async {
    for (var i = 0; i < _targets.length; i++) {
      _targets[i] = _targets[i].copyWith(isFocused: _targets[i].id == id);
    }
    await _saveTargets();
    notifyListeners();
  }

  Future<void> duplicateTarget(String id) async {
    final index = _targets.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final original = _targets[index];
    final copy = TargetItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${original.title} (Copy)',
      targetCount: original.targetCount,
      solvedCount: 0,
      isFocused: false,
      dueDate: original.dueDate,
      priority: original.priority,
      notes: original.notes,
      tags: List.from(original.tags),
      categoryId: original.categoryId,
      links: original.links.map((l) => TargetLink(title: l.title, url: l.url)).toList(),
    );
    _targets.add(copy);
    await _saveTargets();
    notifyListeners();
  }

  // ── Archive mutations ──────────────────────────────────────────────────────
  Future<void> archiveTarget(String id) async {
    final index = _targets.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _archivedTargets.add(_targets[index]);
    final archived = _targets.removeAt(index);
    await _saveTargets();
    await _saveArchive();
    await MissionHistoryService.recordEvent(
      targetId: archived.id,
      type: MissionTimelineEventType.archived,
      description: 'Mission "${archived.title}" archived.',
    );
    notifyListeners();
  }

  Future<void> restoreTarget(String id) async {
    final index = _archivedTargets.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _targets.add(_archivedTargets[index]);
    _archivedTargets.removeAt(index);
    await _saveTargets();
    await _saveArchive();
    notifyListeners();
  }

  Future<void> deleteArchivedTarget(String id) async {
    _archivedTargets.removeWhere((item) => item.id == id);
    await _saveArchive();
    notifyListeners();
  }

  // ── Import / Export Backup ────────────────────────────────────────────────
  Future<String> exportBackup() async {
    final backup = {
      'targets': _targets.map((t) => t.toJson()).toList(),
      'checklist_items': _checklistItems.map((c) => c.toJson()).toList(),
      'archived_targets': _archivedTargets.map((t) => t.toJson()).toList(),
      'categories': _categories.map((c) => c.toJson()).toList(),
      'streak_current': _currentStreak,
      'streak_best': _bestStreak,
      'streak_last_date': _lastActivityDate,
      'daily_activity': _dailyActivity,
    };
    return jsonEncode(backup);
  }

  Future<bool> importBackup(String backupJson) async {
    try {
      final decoded = jsonDecode(backupJson) as Map<String, dynamic>;
      
      final prefs = await SharedPreferences.getInstance();

      if (decoded.containsKey('categories')) {
        final rawCats = decoded['categories'] as List<dynamic>;
        _categories.clear();
        _categories.addAll(rawCats.whereType<Map<String, dynamic>>().map(CategoryItem.fromJson));
        await prefs.setString(_categoriesKey, jsonEncode(rawCats));
      }

      if (decoded.containsKey('targets')) {
        final rawTargs = decoded['targets'] as List<dynamic>;
        _targets.clear();
        _targets.addAll(rawTargs.whereType<Map<String, dynamic>>().map(TargetItem.fromJson));
        await prefs.setString(_targetsKey, jsonEncode(rawTargs));
      }

      if (decoded.containsKey('checklist_items')) {
        final rawCheck = decoded['checklist_items'] as List<dynamic>;
        _checklistItems.clear();
        _checklistItems.addAll(rawCheck.whereType<Map<String, dynamic>>().map(ChecklistItem.fromJson));
        await prefs.setString(_checklistKey, jsonEncode(rawCheck));
      }

      if (decoded.containsKey('archived_targets')) {
        final rawArch = decoded['archived_targets'] as List<dynamic>;
        _archivedTargets.clear();
        _archivedTargets.addAll(rawArch.whereType<Map<String, dynamic>>().map(TargetItem.fromJson));
        await prefs.setString(_archiveKey, jsonEncode(rawArch));
      }

      if (decoded.containsKey('streak_current')) {
        _currentStreak = decoded['streak_current'] as int;
        await prefs.setInt(_streakCurrentKey, _currentStreak);
      }
      if (decoded.containsKey('streak_best')) {
        _bestStreak = decoded['streak_best'] as int;
        await prefs.setInt(_streakBestKey, _bestStreak);
      }
      if (decoded.containsKey('streak_last_date')) {
        _lastActivityDate = decoded['streak_last_date'] as String?;
        if (_lastActivityDate != null) {
          await prefs.setString(_streakLastKey, _lastActivityDate!);
        } else {
          await prefs.remove(_streakLastKey);
        }
      }

      if (decoded.containsKey('daily_activity')) {
        final rawAct = decoded['daily_activity'] as Map<String, dynamic>;
        _dailyActivity.clear();
        for (final entry in rawAct.entries) {
          _dailyActivity[entry.key] = (entry.value as List<dynamic>).cast<String>();
        }
        await prefs.setString(_activityKey, jsonEncode(rawAct));
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AppState.importBackup] Error: $e');
      return false;
    }
  }

  // ── Private persistence ────────────────────────────────────────────────────
  Future<void> _saveTargets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _targetsKey, jsonEncode(_targets.map((t) => t.toJson()).toList()));
    debugPrint('[AppState._saveTargets] saved ${_targets.length}');
  }

  Future<void> _saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _checklistKey, jsonEncode(_checklistItems.map((c) => c.toJson()).toList()));
    debugPrint('[AppState._saveChecklist] saved ${_checklistItems.length}');
  }

  Future<void> _saveArchive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _archiveKey, jsonEncode(_archivedTargets.map((t) => t.toJson()).toList()));
    debugPrint('[AppState._saveArchive] saved ${_archivedTargets.length}');
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _categoriesKey, jsonEncode(_categories.map((c) => c.toJson()).toList()));
    debugPrint('[AppState._saveCategories] saved ${_categories.length}');
  }

  Future<void> _saveSort() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortKey, _sortOption.name);
  }

  Future<void> _saveStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_streakCurrentKey, _currentStreak);
    await prefs.setInt(_streakBestKey, _bestStreak);
    if (_lastActivityDate != null) {
      await prefs.setString(_streakLastKey, _lastActivityDate!);
    }
    debugPrint('[AppState._saveStreak] current=$_currentStreak, best=$_bestStreak');
  }

  Future<void> _saveActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _activityKey,
        jsonEncode(_dailyActivity.map((k, v) => MapEntry(k, v))));
  }

  Future<void> _saveActiveMission() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeMission == null) {
      await prefs.remove(_activeMissionKey);
    } else {
      await prefs.setString(_activeMissionKey, jsonEncode(_activeMission!.toJson()));
    }
  }

  Future<void> _saveMissionStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_missionStatsKey, jsonEncode(_missionStats.toJson()));
  }

  // ── Streak helpers ─────────────────────────────────────────────────────────

  void _updateStreak() {
    final today     = _todayString();
    if (_lastActivityDate == today) return; // already counted today
    final yesterday =
        _dateString(DateTime.now().subtract(const Duration(days: 1)));
    _currentStreak = (_lastActivityDate == yesterday) ? _currentStreak + 1 : 1;
    _lastActivityDate = today;
    if (_currentStreak > _bestStreak) _bestStreak = _currentStreak;
  }

  void _recordTargetActivity(String targetId) {
    final today    = _todayString();
    final existing = _dailyActivity[today] ?? [];
    if (!existing.contains(targetId)) {
      _dailyActivity[today] = [...existing, targetId];
    }
  }

  String _todayString() => _dateString(DateTime.now());

  String _dateString(DateTime date) =>
      '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  // ── Utilities ──────────────────────────────────────────────────────────────
  DateTime? _dateOnly(DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }
}
