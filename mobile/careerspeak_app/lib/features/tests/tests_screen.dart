import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/repository_providers.dart';
import '../../domain/practice_test.dart';

class TestsScreen extends ConsumerWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsPage = ref.watch(practiceTestPageProvider);

    return testsPage.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 42),
              SizedBox(height: 12),
              Text('Could not load practice tests.'),
              SizedBox(height: 6),
              Text('Check your connection and try again.'),
            ],
          ),
        ),
      ),
      data: (page) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            'Practice tests',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Test your knowledge, find weak spots and build confidence before the real interview or exam.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (page.items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.quiz_outlined, size: 40),
                    SizedBox(height: 12),
                    Text('No practice tests are available yet.'),
                  ],
                ),
              ),
            )
          else
            for (final test in page.items) ...[
              _TestCard(test: test),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.test});

  final PracticeTestSummary test;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconFor(test.mode),
                    color: scheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _modeLabel(test.mode),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(test.subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, size: 18),
                const SizedBox(width: 6),
                Text('${test.questionCount} questions'),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/tests/${test.code}'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _modeLabel(PracticeTestMode mode) {
    return switch (mode) {
      PracticeTestMode.learn => 'LEARN MODE',
      PracticeTestMode.exam => 'EXAM MODE',
      PracticeTestMode.quick => 'QUICK TEST',
    };
  }

  IconData _iconFor(PracticeTestMode mode) {
    return switch (mode) {
      PracticeTestMode.learn => Icons.school_outlined,
      PracticeTestMode.exam => Icons.assignment_outlined,
      PracticeTestMode.quick => Icons.bolt_rounded,
    };
  }
}
