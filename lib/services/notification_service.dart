import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (kIsWeb) return;
      if (Platform.isAndroid) {
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const initSettings = InitializationSettings(android: androidSettings);
        await _plugin.initialize(initSettings);
        _initialized = true;
      } else if (Platform.isWindows) {
        // flutter_local_notifications has windows support in newer versions but requires native configurations.
        // We initialize it within a try-catch block to guarantee safety.
        const initSettings = InitializationSettings();
        await _plugin.initialize(initSettings);
        _initialized = true;
      }
    } catch (e) {
      debugPrint('[NotificationService] Initialization failed: $e');
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      if (kIsWeb) return;
      if (Platform.isAndroid) {
        const androidDetails = AndroidNotificationDetails(
          'checklist_reminders',
          'Checklist Reminders',
          channelDescription: 'Reminders for checklist targets and streaks',
          importance: Importance.high,
          priority: Priority.high,
        );
        const details = NotificationDetails(android: androidDetails);
        await _plugin.show(id, title, body, details);
      } else {
        // Fallback for Windows or other platforms in case they fail plugin check
        // Or if plugin is initialized, we trigger it.
        if (_initialized) {
          const details = NotificationDetails();
          await _plugin.show(id, title, body, details);
        } else {
          debugPrint('[NotificationService] Not initialized. Notification: $title - $body');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Show failed: $e');
    }
  }

  // Trigger checks for daily target incomplete, upcoming deadlines, missed streak
  static Future<void> checkAndNotify({
    required int activeTargetsIncomplete,
    required int streak,
    required int problemsSolvedToday,
    required List<dynamic> upcomingDeadlines,
  }) async {
    await initialize();
    
    // 1. Today's target not completed
    if (activeTargetsIncomplete > 0 && problemsSolvedToday == 0) {
      await showNotification(
        id: 101,
        title: "Today's Targets Incomplete",
        body: "You have $activeTargetsIncomplete active target(s) left. Work on them to keep your progress going!",
      );
    }

    // 2. Missed streak
    if (streak > 0 && problemsSolvedToday == 0) {
      await showNotification(
        id: 102,
        title: "Keep the Streak Alive! 🔥",
        body: "Your daily streak of $streak days is at risk! Complete at least one target problem today.",
      );
    }

    // 3. Upcoming deadline (e.g. deadline is tomorrow/today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final target in upcomingDeadlines) {
      if (target.dueDate != null) {
        final due = DateTime(target.dueDate!.year, target.dueDate!.month, target.dueDate!.day);
        final difference = due.difference(today).inDays;
        if (difference == 1) {
          await showNotification(
            id: target.id.hashCode,
            title: "Upcoming Deadline Tomorrow",
            body: "Target \"${target.title}\" is due tomorrow!",
          );
        } else if (difference == 0) {
          await showNotification(
            id: target.id.hashCode,
            title: "Target Due Today!",
            body: "Target \"${target.title}\" is due today!",
          );
        }
      }
    }
  }
}
