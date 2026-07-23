import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:checklist/main.dart';
import 'package:checklist/providers/app_state.dart';
import 'package:checklist/screens/home_screen.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ChecklistApp());

    expect(find.text('Streak & Summary'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });


  testWidgets('HomeScreen can add a new checklist item on Targets tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Switch to Targets tab (tab index 1)
    await tester.tap(find.byIcon(Icons.check_box_outlined));
    await tester.pumpAndSettle();

    // Find checklist input by hint text
    final checklistInput = find.byType(TextField).first;
    expect(checklistInput, findsOneWidget);

    await tester.enterText(checklistInput, 'Write tests');
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    expect(find.text('Write tests'), findsOneWidget);
  });
}
