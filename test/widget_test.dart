import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checklist/main.dart';
import 'package:checklist/providers/app_state.dart';
import 'package:checklist/providers/planner_provider.dart';
import 'package:checklist/providers/coach_provider.dart';
import 'package:checklist/providers/learning_provider.dart';
import 'package:checklist/providers/behavior_provider.dart';
import 'package:checklist/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ChecklistApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('HomeScreen can navigate to Targets tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => PlannerProvider()),
          ChangeNotifierProvider(create: (_) => CoachProvider()),
          ChangeNotifierProvider(create: (_) => LearningProvider()),
          ChangeNotifierProvider(create: (_) => BehaviorProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Targets tab (tab index 2 - rocket icon)
    await tester.tap(find.byIcon(Icons.rocket_launch_outlined));
    await tester.pumpAndSettle();

    // Expect Targets title on the tab header
    expect(find.text('Targets'), findsWidgets);
  });
}
