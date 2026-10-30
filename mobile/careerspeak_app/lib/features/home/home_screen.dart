import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/content_locations.dart';
import '../../app/learner_state_providers.dart';
import '../../app/repository_providers.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentPage = ref.watch(contentPageProvider);
    final markers = ref.watch(contentMarkersProvider);

    return contentPage.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _HomeLoadError(error: error),
      data: (page) => markers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _HomeLoadError(error: error),
        data: (values) => _HomeContent(items: page.items, markers: values),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.items, required this.markers});

  final List<ContentItem> items;
  final Map<ContentIdentity, ContentMarkerState> markers;

  ContentMarkerState markerFor(ContentItem item) =>
      markers[ContentIdentity.fromItem(item)] ?? const ContentMarkerState();

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) => markerFor(item).completed).length;
    final listened = items.where((item) => markerFor(item).listened).length;
    final favorites = items.where((item) => markerFor(item).favorite).length;
    final due = items.length - completed;

    ContentItem? continueItem;
    for (final item in items) {
      if (!markerFor(item).completed) {
        continueItem = item;
        break;
      }
    }
    continueItem ??= items.isEmpty ? null : items.first;

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
        Text('Your learning', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              icon: Icons.check_circle_outline,
              label: 'Completed',
              value: '$completed',
            ),
            _StatCard(
              icon: Icons.headphones_outlined,
              label: 'Listened',
              value: '$listened',
            ),
            _StatCard(
              icon: Icons.favorite_outline,
              label: 'Favorites',
              value: '$favorites',
            ),
            _StatCard(icon: Icons.replay_outlined, label: 'Due', value: '$due'),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Continue learning',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (continueItem == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No learning content is available yet.'),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    continueItem.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(continueItem.subtitle),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: items.isEmpty ? 0 : completed / items.length,
                  ),
                  const SizedBox(height: 8),
                  Text('$completed of ${items.length} items completed'),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      contentDetailLocation(
                        ContentIdentity.fromItem(continueItem!),
                      ),
                    ),
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

class _HomeLoadError extends StatelessWidget {
  const _HomeLoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Unable to load learning content.\n$error'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 12),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
