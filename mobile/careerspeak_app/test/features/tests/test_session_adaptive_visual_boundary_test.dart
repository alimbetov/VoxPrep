import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/application/ports/practice_test_attempt_repository.dart';
import 'package:careerspeak_app/application/ports/practice_test_repository.dart';
import 'package:careerspeak_app/application/query/page.dart';
import 'package:careerspeak_app/application/query/practice_test_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/practice_test.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:careerspeak_app/domain/practice_test_completion_key.dart';
import 'package:careerspeak_app/features/tests/test_session_screen.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/ui_boundary_harness.dart';

void main() {
  for (final boundary in adaptiveUiBoundaryCases) {
    testWidgets('Practice test survives long text for $boundary', (
      tester,
    ) async {
      final attemptRepository = _PracticeTestAttemptRepository();
      await pumpAdaptiveSurface(
        tester,
        boundary: boundary,
        child: ProviderScope(
          overrides: [
            practiceTestRepositoryProvider.overrideWithValue(
              const _PracticeTestRepository(),
            ),
            practiceTestAttemptRepositoryProvider.overrideWithValue(
              attemptRepository,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: TestSessionScreen(code: 'LONG_TEST')),
          ),
        ),
      );

      expectNoLayoutExceptions(
        tester,
        reason: 'Practice test intro must fit $boundary',
      );
      expect(find.text(_longTitle), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Start test'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Start test'));
      await tester.pumpAndSettle();

      expectNoLayoutExceptions(
        tester,
        reason: 'Practice question must fit $boundary',
      );
      expect(find.text(_longPrompt), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(_optionA),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(_optionA));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Submit'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expectNoLayoutExceptions(
        tester,
        reason: 'Practice result must fit $boundary',
      );
      await tester.scrollUntilVisible(
        find.text('Review answers'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Review answers'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('1. '),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.textContaining('1. '));
      await tester.pumpAndSettle();

      expectNoLayoutExceptions(
        tester,
        reason: 'Expanded answer review must fit $boundary',
      );
      await tester.scrollUntilVisible(
        find.textContaining('Correct answer:'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Correct answer:'), findsOneWidget);
    });
  }
}

const _longTitle =
    'Очень длинный заголовок тренировочного теста для проверки адаптивной верстки профессионального интервью';
const _longPrompt =
    'Представьте, что вам необходимо подробно объяснить коллегам очень длинный технический сценарий с несколькими условиями и выбрать наиболее корректный ответ без визуального переполнения интерфейса.';
const _optionA =
    'Первый длинный вариант ответа, содержащий достаточно текста для переноса на несколько строк на небольшом экране.';

const _test = PracticeTest(
  code: 'LONG_TEST',
  title: _longTitle,
  subtitle:
      'Подзаголовок также намеренно длинный, чтобы проверить переносы текста, крупный масштаб шрифта и узкие устройства.',
  mode: PracticeTestMode.learn,
  questions: [
    PracticeQuestion(
      code: 'Q1',
      prompt: _longPrompt,
      options: [
        _optionA,
        'Второй длинный вариант ответа для проверки многострочного RadioListTile и сохранения доступной области касания.',
        'Третий вариант с дополнительным описанием, который не должен вызывать RenderFlex overflow или clipping.',
        'Четвёртый вариант ответа с ещё более длинной формулировкой для стрессовой проверки визуальных границ.',
      ],
      correctIndex: 0,
      skill:
          'Очень длинное название профессионального навыка и компетенции для интервью',
      explanation:
          'Развёрнутое объяснение ответа также должно корректно переноситься внутри ExpansionTile на любом поддерживаемом размере экрана.',
    ),
  ],
);

final class _PracticeTestRepository implements PracticeTestRepository {
  const _PracticeTestRepository();

  @override
  Future<Result<PracticeTest?>> getByCode(String code) async =>
      Success<PracticeTest?>(code == _test.code ? _test : null);

  @override
  Stream<Result<Page<PracticeTestSummary>>> watchTests(
    PracticeTestQuery query,
  ) => const Stream<Result<Page<PracticeTestSummary>>>.empty();
}

final class _PracticeTestAttemptRepository
    implements PracticeTestAttemptRepository {
  PracticeTestAttempt? _active;
  final Set<PracticeTestCompletionKey> _completed =
      <PracticeTestCompletionKey>{};

  @override
  Future<Result<PracticeTestAttempt?>> getActiveAttempt() async =>
      Success<PracticeTestAttempt?>(_active);

  @override
  Future<Result<PracticeTestAttempt>> startActiveAttempt(String code) async {
    final now = DateTime.utc(2026, 11, 1, 10);
    _active = PracticeTestAttempt(
      practiceTestCode: code,
      practiceTestRevision: 1,
      currentIndex: 0,
      answers: const <int, int>{},
      startedAt: now,
      updatedAt: now,
    );
    return Success<PracticeTestAttempt>(_active!);
  }

  @override
  Future<Result<PracticeTestAttempt>> saveActiveAttempt(
    PracticeTestAttempt attempt,
  ) async {
    _active = attempt;
    return Success<PracticeTestAttempt>(attempt);
  }

  @override
  Future<Result<Set<PracticeTestCompletionKey>>>
  getCompletedPracticeTests() async => Success<Set<PracticeTestCompletionKey>>(
    Set<PracticeTestCompletionKey>.unmodifiable(_completed),
  );

  @override
  Future<Result<void>> completeActiveAttempt() async {
    final active = _active;
    if (active != null) {
      _completed.add(
        PracticeTestCompletionKey(
          practiceTestCode: active.practiceTestCode,
          revision: active.practiceTestRevision,
        ),
      );
      _active = null;
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> clearActiveAttempt() async {
    _active = null;
    return const Success<void>(null);
  }
}
