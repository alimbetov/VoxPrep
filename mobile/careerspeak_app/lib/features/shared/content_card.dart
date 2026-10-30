import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import 'content_marker_chips.dart';

class ContentCard extends ConsumerWidget {
  const ContentCard({
    required this.item,
    this.onTap,
    this.selected = false,
    super.key,
  });

  final ContentItem item;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(contentMarkersProvider);
    final markerState = markers[item.code] ?? const ContentMarkerState();
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? scheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap ?? () => context.push('/content/${item.code}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Icon(_iconFor(item.type))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(item.subtitle),
                    const SizedBox(height: 10),
                    ContentMarkerChips(state: markerState),
                  ],
                ),
              ),
              IconButton(
                tooltip: markerState.favorite ? 'Remove favorite' : 'Add favorite',
                onPressed: () => ref
                    .read(contentMarkersProvider.notifier)
                    .toggleFavorite(item.code),
                icon: Icon(
                  markerState.favorite ? Icons.favorite : Icons.favorite_border,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(ContentType type) {
    return switch (type) {
      ContentType.vocabulary => Icons.menu_book,
      ContentType.interview => Icons.work_outline,
      ContentType.topic => Icons.article_outlined,
      ContentType.shadowing => Icons.record_voice_over_outlined,
      ContentType.phrase => Icons.chat_bubble_outline,
    };
  }
}
