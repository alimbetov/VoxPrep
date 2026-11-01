import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/learner_state_providers.dart';
import '../../app/repository_providers.dart';
import '../../app/review_schedule_providers.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_card.dart';

enum _ReviewFilter { due, favorites, notListened }

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  _ReviewFilter filter = _ReviewFilter.due;

  @override
  Widget build(BuildContext context) {
    final contentPage = ref.watch(contentPageProvider);
    final markers = ref.watch(contentMarkersProvider);
    final dueReviewItems = ref.watch(dueReviewItemsProvider);

    return contentPage.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load review content.\n$error'),
        ),
      ),
      data: (page) => markers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load learner state.\n$error'),
          ),
        ),
        data: (values) {
          final due = dueReviewItems.asData?.value ?? const <ContentItem>[];
          final items = _itemsFor(page.items, values, due);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Review', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                'Use learner markers and scheduled review dates to return to material that needs attention.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Due'),
                    selected: filter == _ReviewFilter.due,
                    onSelected: (_) =>
                        setState(() => filter = _ReviewFilter.due),
                  ),
                  FilterChip(
                    label: const Text('Favorites'),
                    selected: filter == _ReviewFilter.favorites,
                    onSelected: (_) =>
                        setState(() => filter = _ReviewFilter.favorites),
                  ),
                  FilterChip(
                    label: const Text('Not listened'),
                    selected: filter == _ReviewFilter.notListened,
                    onSelected: (_) =>
                        setState(() => filter = _ReviewFilter.notListened),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${items.length} items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (filter == _ReviewFilter.due && dueReviewItems.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              if (filter == _ReviewFilter.due && dueReviewItems.hasError)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Due review state is temporarily unavailable.'),
                ),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text('Nothing matches this review filter.'),
                  ),
                )
              else
                for (final item in items) ContentCard(item: item),
            ],
          );
        },
      ),
    );
  }

  List<ContentItem> _itemsFor(
    List<ContentItem> all,
    Map<ContentIdentity, ContentMarkerState> markers,
    List<ContentItem> dueReviewItems,
  ) {
    if (filter == _ReviewFilter.due) {
      return dueReviewItems;
    }
    return all
        .where((item) {
          final identity = ContentIdentity.fromItem(item);
          final state = markers[identity] ?? const ContentMarkerState();
          return switch (filter) {
            _ReviewFilter.due => false,
            _ReviewFilter.favorites => state.favorite,
            _ReviewFilter.notListened => item.hasAudio && !state.listened,
          };
        })
        .toList(growable: false);
  }
}
