import 'package:flutter/material.dart';

/// Personalities available for the Coach Engine.
enum CoachPersonality {
  /// Friendly, encouraging tone focusing on gradual growth.
  mentor,

  /// Professional, objective, matter-of-fact tone.
  balanced,

  /// Direct, firm, high-standard, action-first tone.
  drillSergeant,

  /// Competitive, performance-focused challenge tone.
  rival,

  /// Calm, principled, discipline-centered guidance.
  stoic,
}

extension CoachPersonalityExt on CoachPersonality {
  String get displayName => switch (this) {
        CoachPersonality.mentor => 'Mentor',
        CoachPersonality.balanced => 'Balanced',
        CoachPersonality.drillSergeant => 'Drill Sergeant',
        CoachPersonality.rival => 'Rival',
        CoachPersonality.stoic => 'Stoic',
      };

  String get subtitle => switch (this) {
        CoachPersonality.mentor => 'Friendly & Encouraging',
        CoachPersonality.balanced => 'Professional & Objective',
        CoachPersonality.drillSergeant => 'Direct & High Standard',
        CoachPersonality.rival => 'Competitive & Challenging',
        CoachPersonality.stoic => 'Calm & Principled',
      };

  String get sampleQuote => switch (this) {
        CoachPersonality.mentor => 'Progress is built one mission at a time.',
        CoachPersonality.balanced =>
          "Today's plan looks realistic. Let's execute it.",
        CoachPersonality.drillSergeant =>
          'Planning is finished. Execution starts now.',
        CoachPersonality.rival =>
          "Yesterday's version of you completed more work. Let's change that.",
        CoachPersonality.stoic =>
          'Discipline is remembering what you wanted.',
      };

  IconData get icon => switch (this) {
        CoachPersonality.mentor => Icons.sentiment_satisfied_alt_rounded,
        CoachPersonality.balanced => Icons.psychology_rounded,
        CoachPersonality.drillSergeant => Icons.fitness_center_rounded,
        CoachPersonality.rival => Icons.military_tech_rounded,
        CoachPersonality.stoic => Icons.self_improvement_rounded,
      };
}
