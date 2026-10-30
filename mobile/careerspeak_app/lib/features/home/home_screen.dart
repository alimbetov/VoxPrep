import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_content_repository.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(mockContentRepositoryProvider);
    final markers = ref.watch(contentMarkersProvider);
    final items = repository.all;
    final completed = markers.values.where((state) => state.completed).length;
    final continueItem = items.firstWhere(
      (item) => !(markers[item.code]?.completed ?? false),
      orElse: () => items.first,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('CareerSpeak', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Professional English, IELTS and interview practice.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text('Continue learning', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(continueItem.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(continueItem.subtitle),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: items.isEmpty ? 0 : completed / items.length,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/content/${continueItem.code}'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Quick access', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.school_outlined),
              label: const Text('Learn'),
              onPressed: () => context.go('/learn'),
            ),
            ActionChip(
              avatar: const Icon(Icons.quiz_outlined),
              label: const Text('Quick test'),
              onPressed: () => context.go('/tests'),
            ),
            ActionChip(
              avatar: const Icon(Icons.replay_outlined),
              label: const Text('Daily review'),
              onPressed: () => context.go('/review'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Recommended', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final item in items.take(3)) ContentCard(item: item),
      ],
    );
  }
}
