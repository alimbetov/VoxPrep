import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/learner_state_providers.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_marker_chips.dart';

class ContentDetailPanel extends ConsumerWidget {
  const ContentDetailPanel({required this.item, super.key});

  final ContentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ContentIdentity.fromItem(item);
    final markers = ref.watch(contentMarkersProvider);

    return markers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load learner state.\n$error'),
        ),
      ),
      data: (values) {
        final marker = values[identity] ?? const ContentMarkerState();
        return _buildContent(context, ref, identity, marker);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ContentIdentity identity,
    ContentMarkerState marker,
  ) {
    final repository = ref.read(learnerStateRepositoryProvider);

    Future<void> write(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update learner state: $error')),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(item.subtitle),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: marker.favorite ? 'Remove favorite' : 'Add favorite',
              onPressed: () => write(() async {
                (await repository.setFavorite(
                  identity,
                  favorite: !marker.favorite,
                )).getOrThrow();
              }),
              icon: Icon(
                marker.favorite ? Icons.favorite : Icons.favorite_border,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ContentMarkerChips(state: marker),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (item.hasAudio)
              FilledButton.tonalIcon(
                onPressed: () => write(() async {
                  (await repository.setListened(
                    identity,
                    listened: !marker.listened,
                  )).getOrThrow();
                }),
                icon: Icon(marker.listened ? Icons.replay : Icons.headphones),
                label: Text(marker.listened ? 'Reset listened' : 'Mock listen'),
              ),
            FilledButton.icon(
              onPressed: () => write(() async {
                (await repository.setCompleted(
                  identity,
                  completed: !marker.completed,
                )).getOrThrow();
              }),
              icon: Icon(
                marker.completed ? Icons.restart_alt : Icons.check_circle,
              ),
              label: Text(
                marker.completed ? 'Mark incomplete' : 'Mark completed',
              ),
            ),
          ],
        ),
        if (marker.lastPositionMs case final position?) ...[
          const SizedBox(height: 12),
          Text('Saved playback position: ${position} ms'),
        ],
        const SizedBox(height: 32),
        Text('Overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mock learning content',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Content remains curated in-memory data in P2.2. Learner state is now persisted through Drift and survives application restart.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
