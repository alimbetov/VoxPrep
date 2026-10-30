import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/repository_providers.dart';
import '../../domain/mock_practice_test.dart';
import 'mock_test_session_controller.dart';

class TestSessionScreen extends ConsumerWidget {
  const TestSessionScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(practiceTestRepositoryProvider);
    final test = repository.byCode(code);

    if (test == null) {
      return const Center(child: Text('Test not found.'));
    }

    final session = ref.watch(mockTestSessionProvider);
    final controller = ref.read(mockTestSessionProvider.notifier);

    if (session.testCode != code) {
      return _TestIntro(
        test: test,
        onStart: () => controller.start(test.code),
      );
    }

    if (session.submitted) {
      return _TestResult(
        test: test,
        session: session,
        onRetake: () => controller.start(test.code),
      );
    }

    return _QuestionSession(test: test, session: session);
  }
}

class _TestIntro extends StatelessWidget {
  const _TestIntro({required this.test, required this.onStart});

  final MockPracticeTest test;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Test', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Text(test.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(test.subtitle),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Practice session',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text('${test.questions.length} questions'),
                const SizedBox(height: 6),
                Text('Mode: ${test.mode.name.toUpperCase()}'),
                const SizedBox(height: 12),
                const Text(
                  'Session state remains in Riverpod during P2. Persistent attempt storage is introduced by a later production adapter slice.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start test'),
          ),
        ),
      ],
    );
  }
}

class _QuestionSession extends ConsumerWidget {
  const _QuestionSession({required this.test, required this.session});

  final MockPracticeTest test;
  final MockTestSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(mockTestSessionProvider.notifier);
    final question = test.questions[session.currentIndex];
    final selected = session.answers[session.currentIndex];
    final wide = MediaQuery.sizeOf(context).width >= 840;

    final questionPane = _QuestionPane(
      test: test,
      question: question,
      session: session,
      selected: selected,
      onSelect: controller.selectAnswer,
      onPrevious: controller.previous,
      onNext: () => controller.next(test.questions.length),
      onSubmit: controller.submit,
    );

    if (!wide) {
      return questionPane;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: questionPane),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 280,
          child: _QuestionNavigator(
            total: test.questions.length,
            current: session.currentIndex,
            answered: session.answers.keys.toSet(),
            onSelect: (index) =>
                controller.goTo(index, test.questions.length),
          ),
        ),
      ],
    );
  }
}

class _QuestionPane extends StatelessWidget {
  const _QuestionPane({
    required this.test,
    required this.question,
    required this.session,
    required this.selected,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final MockPracticeTest test;
  final MockQuestion question;
  final MockTestSessionState session;
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final last = session.currentIndex == test.questions.length - 1;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 520 || textScale >= 1.6;
            final progressText = Text(
              'Question ${session.currentIndex + 1} of ${test.questions.length}',
              style: Theme.of(context).textTheme.titleMedium,
            );
            final skill = Chip(label: Text(question.skill));

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  progressText,
                  const SizedBox(height: 8),
                  skill,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: progressText),
                const SizedBox(width: 12),
                skill,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (session.currentIndex + 1) / test.questions.length,
        ),
        const SizedBox(height: 28),
        Text(
          question.prompt,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        RadioGroup<int>(
          groupValue: selected,
          onChanged: (value) {
            if (value != null) onSelect(value);
          },
          child: Column(
            children: [
              for (var index = 0; index < question.options.length; index++)
                Card(
                  child: RadioListTile<int>(
                    value: index,
                    selected: selected == index,
                    title: Text(question.options[index]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 360 || textScale >= 2.0;
            final previous = OutlinedButton.icon(
              onPressed: session.currentIndex == 0 ? null : onPrevious,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            );
            final next = last
                ? FilledButton.icon(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.flag),
                    label: const Text('Submit'),
                  )
                : FilledButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  previous,
                  const SizedBox(height: 12),
                  next,
                ],
              );
            }

            return Row(
              children: [
                previous,
                const Spacer(),
                next,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuestionNavigator extends StatelessWidget {
  const _QuestionNavigator({
    required this.total,
    required this.current,
    required this.answered,
    required this.onSelect,
  });

  final int total;
  final int current;
  final Set<int> answered;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Questions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < total; index++)
              FilterChip(
                selected: index == current,
                avatar: answered.contains(index)
                    ? const Icon(Icons.check, size: 18)
                    : null,
                label: Text('${index + 1}'),
                onSelected: (_) => onSelect(index),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('${answered.length} of $total answered'),
      ],
    );
  }
}

class _TestResult extends StatelessWidget {
  const _TestResult({
    required this.test,
    required this.session,
    required this.onRetake,
  });

  final MockPracticeTest test;
  final MockTestSessionState session;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final score = calculateMockTestScore(test, session.answers);
    final percent = ((score / test.questions.length) * 100).round();
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Result', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 520 || textScale >= 1.6;
                final scoreSummary = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$score / ${test.questions.length} correct',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('${session.answers.length} answered'),
                  ],
                );
                final retake = FilledButton.tonalIcon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.replay),
                  label: const Text('Retake'),
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        child: Text('$percent%'),
                      ),
                      const SizedBox(height: 16),
                      scoreSummary,
                      const SizedBox(height: 16),
                      retake,
                    ],
                  );
                }

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      child: Text('$percent%'),
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: scoreSummary),
                    const SizedBox(width: 16),
                    retake,
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Review answers',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < test.questions.length; index++)
          _AnswerReview(
            number: index + 1,
            question: test.questions[index],
            selectedIndex: session.answers[index],
          ),
      ],
    );
  }
}

class _AnswerReview extends StatelessWidget {
  const _AnswerReview({
    required this.number,
    required this.question,
    required this.selectedIndex,
  });

  final int number;
  final MockQuestion question;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final correct = selectedIndex == question.correctIndex;
    final selectedText =
        selectedIndex == null ? 'No answer' : question.options[selectedIndex!];
    final correctText = question.options[question.correctIndex];

    return Card(
      child: ExpansionTile(
        leading: Icon(
          correct ? Icons.check_circle : Icons.cancel,
          color: correct
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text('$number. ${question.prompt}'),
        subtitle: Text(correct ? 'Correct' : 'Review needed'),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your answer: $selectedText'),
          const SizedBox(height: 6),
          Text('Correct answer: $correctText'),
          const SizedBox(height: 10),
          Text(question.explanation),
        ],
      ),
    );
  }
}
