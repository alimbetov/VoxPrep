import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_marker_chips.dart';

class ContentDetailPanel extends ConsumerWidget {
  const ContentDetailPanel({required this.item, super.key});

  final ContentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(contentMarkersProvider);
    final marker = markers[item.code] ?? const ContentMarkerState();
    final controller = ref.read(contentMarkersProvider.notifier);

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
              onPressed: () => controller.toggleFavorite(item.code),
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
                onPressed: () {
                  controller.toggleListened(item.code);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        marker.listened
                            ? 'Mock: marked as not listened.'
                            : 'Mock audio completed: marked as listened.',
                      ),
                    ),
                  );
                },
                icon: Icon(marker.listened ? Icons.replay : Icons.headphones),
                label: Text(marker.listened ? 'Reset listened' : 'Mock listen'),
              ),
            FilledButton.icon(
              onPressed: () => controller.toggleCompleted(item.code),
              icon: Icon(
                marker.completed ? Icons.restart_alt : Icons.check_circle,
              ),
              label: Text(
                marker.completed ? 'Mark incomplete' : 'Mark completed',
              ),
            ),
          ],
        ),
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
                  'This vertical slice intentionally uses curated in-memory data. The same presentation contract will later bind to Drift and Backend repositories.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
