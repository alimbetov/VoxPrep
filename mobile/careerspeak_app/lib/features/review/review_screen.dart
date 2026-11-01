import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/learner_state_providers.dart';
import '../../app/repository_providers.dart';
import '../../app/review_policy_providers.dart';
import '../../app/review_schedule_providers.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../../domain/content_review_state.dart';
import '../shared/content_card.dart';

enum _ReviewFilter { due, favorites, notListened }

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  _ReviewFilter filter = _ReviewFilter.due;
  final Set<ContentIdentity> _submitting = <ContentIdentity>{};

  @override
  Widget build(BuildContext context) {
    final contentPage = ref.watch(contentPageProvider);
    final markers = ref.watch(contentMarkersProvider);
    final dueReviewItems = ref.watch(dueReviewItemsProvider);
    final schedules = ref.watch(reviewSchedulesProvider);

    return contentPage.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Unable to load review content. Please try again.'),
        ),
      ),
      data: (page) => markers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Unable to load learner state. Please try again.'),
          ),
        ),
        data: (values) {
          final due = dueReviewItems.asData?.value ?? const <ContentItem>[];
          final scheduleValues =
              schedules.asData?.value ?? const <ContentIdentity, ContentReviewState>{};
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
              else if (filter == _ReviewFilter.due)
                for (final item in items)
                  _DueReviewItem(
                    item: item,
                    schedule: scheduleValues[ContentIdentity.fromItem(item)],
                    submitting: _submitting.contains(ContentIdentity.fromItem(item)),
                    onOutcome: (outcome) => _recordOutcome(item, outcome),
                  )
              else
                for (final item in items) ContentCard(item: item),
            ],
          );
        },
      ),
    );
  }

  Future<void> _recordOutcome(ContentItem item, ReviewOutcome outcome) async {
    final identity = ContentIdentity.fromItem(item);
    final schedules = ref.read(reviewSchedulesProvider).asData?.value;
    final schedule = schedules?[identity];
    if (schedule == null || _submitting.contains(identity)) return;

    setState(() => _submitting.add(identity));
    try {
      final result = await ref.read(reviewSchedulerProvider).recordOutcome(
            identity: identity,
            currentStage: schedule.reviewStage,
            outcome: outcome,
          );
      result.getOrThrow();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save review result. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting.remove(identity));
      }
    }
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

class _DueReviewItem extends StatelessWidget {
  const _DueReviewItem({
    required this.item,
    required this.schedule,
    required this.submitting,
    required this.onOutcome,
  });

  final ContentItem item;
  final ContentReviewState? schedule;
  final bool submitting;
  final ValueChanged<ReviewOutcome> onOutcome;

  @override
  Widget build(BuildContext context) {
    final enabled = schedule != null && !submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContentCard(item: item),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: enabled
                  ? () => onOutcome(ReviewOutcome.incorrect)
                  : null,
              child: const Text('Incorrect'),
            ),
            OutlinedButton(
              onPressed: enabled ? () => onOutcome(ReviewOutcome.hard) : null,
              child: const Text('Hard'),
            ),
            FilledButton.tonal(
              onPressed: enabled
                  ? () => onOutcome(ReviewOutcome.correct)
                  : null,
              child: const Text('Correct'),
            ),
            FilledButton(
              onPressed: enabled ? () => onOutcome(ReviewOutcome.known) : null,
              child: const Text('Known'),
            ),
          ],
        ),
        if (submitting)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
