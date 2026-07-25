import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_state.dart';
import 'providers/behavior_provider.dart';
import 'providers/coach_provider.dart';
import 'providers/learning_provider.dart';
import 'providers/planner_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChecklistApp());
}

class ChecklistApp extends StatelessWidget {
  const ChecklistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..load()),
        // PlannerProvider is independent of AppState — runs carry-forward
        // check on startup via load().
        ChangeNotifierProvider(create: (_) => PlannerProvider()..load()),
        ChangeNotifierProvider(create: (_) => CoachProvider()..load()),
        ChangeNotifierProvider(create: (_) => LearningProvider()..load()),
        ChangeNotifierProvider(create: (_) => BehaviorProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Execution OS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}

