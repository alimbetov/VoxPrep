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
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load tests.\n$error'),
        ),
      ),
      data: (page) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Tests', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'Assessment catalogue qualified against repository ports before production persistence is connected.',
          ),
          const SizedBox(height: 20),
          for (final test in page.items) _TestCard(test: test),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(child: Icon(_iconFor(test.mode))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(test.subtitle),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => context.push('/tests/${test.code}'),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PracticeTestMode mode) {
    return switch (mode) {
      PracticeTestMode.learn => Icons.school,
      PracticeTestMode.exam => Icons.assignment,
      PracticeTestMode.quick => Icons.bolt,
    };
  }
}
