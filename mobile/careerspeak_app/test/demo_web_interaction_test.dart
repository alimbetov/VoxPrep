import 'package:careerspeak_app/demo_web_main.dart';
import 'package:careerspeak_app/data/mock/mock_test_repository.dart';
import 'package:careerspeak_app/application/query/practice_test_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'lessons open, favorites and completion update review, reset clears',
    (tester) async {
      await tester.pumpWidget(const VoxPrepWebDemoApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dependency Injection'));
      await tester.pumpAndSettle();
      expect(find.text('Lesson details'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Add favorite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('1 favorites · 1 completed'), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset demo progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('0 favorites · 0 completed'), findsOneWidget);
    },
  );

  testWidgets('FULL gate cancels, unlock opens lesson; search survives tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const VoxPrepWebDemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('ConcurrentHashMap'));
    await tester.pumpAndSettle();
    expect(find.text('FULL locked — demo only'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ConcurrentHashMap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate FULL'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson details'), findsOneWidget);
    expect(find.text('Add favorite'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Complete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'unmatched-search');
    await tester.pumpAndSettle();
    expect(find.text('No matching demo learning materials.'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'unmatched-search'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Dependency Injection'), findsOneWidget);
  });
  testWidgets('all exams score and retry; settings theme works', (
    tester,
  ) async {
    await tester.pumpWidget(const VoxPrepWebDemoApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark theme'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.text('Tests'));
    await tester.pumpAndSettle();
    final summaries =
        (await const MockTestRepository()
                .watchTests(const PracticeTestQuery())
                .first)
            .getOrThrow()
            .items;
    for (final summary in summaries) {
      final exam = (await const MockTestRepository().getByCode(
        summary.code,
      )).getOrThrow()!;
      await tester.tap(find.text(summary.title));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'))
            .onPressed,
        isNull,
      );
      for (var i = 0; i < exam.questions.length; i++) {
        final question = exam.questions[i];
        await tester.tap(find.text(question.options[question.correctIndex]));
        await tester.pumpAndSettle();
        final next = find.text(
          i == exam.questions.length - 1 ? 'Submit' : 'Next',
        );
        await tester.ensureVisible(next);
        await tester.tap(next);
        await tester.pumpAndSettle();
        if (i == 0) {
          await tester.tap(find.text('Previous'));
          await tester.pumpAndSettle();
          expect(
            find.text('Question 1 / ${exam.questions.length}'),
            findsOneWidget,
          );
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
      expect(
        find.text(
          'Result: ${exam.questions.length} / ${exam.questions.length}',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(
        find.text('Question 1 / ${exam.questions.length}'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Practice tests'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
