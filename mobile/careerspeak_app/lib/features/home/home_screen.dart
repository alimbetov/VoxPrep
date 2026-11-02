import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/continue_learning_providers.dart';
import '../../app/learner_selection_providers.dart';
import '../../app/learner_state_providers.dart';
import '../../app/repository_providers.dart';
import '../../app/review_schedule_providers.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_card.dart';
import '../shared/content_cover.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentPage = ref.watch(contentPageProvider);
    final markers = ref.watch(contentMarkersProvider);
    final dueReviewItems = ref.watch(dueReviewItemsProvider);
    final learningContext = ref.watch(learnerLearningContextProvider);
    final continueLearning = ref.watch(continueLearningHomeTargetProvider);

    return contentPage.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _HomeLoadError(),
      data: (page) => markers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _HomeLoadError(),
        data: (values) => _HomeContent(
          items: page.items,
          markers: values,
          dueReviewItems: dueReviewItems,
          learningContext: learningContext,
          continueLearning: continueLearning,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.items,
    required this.markers,
    required this.dueReviewItems,
    required this.learningContext,
    required this.continueLearning,
  });

  final List<ContentItem> items;
  final Map<ContentIdentity, ContentMarkerState> markers;
  final AsyncValue<List<ContentItem>> dueReviewItems;
  final AsyncValue<LearnerLearningContext?> learningContext;
  final AsyncValue<ContinueLearningHomeTarget> continueLearning;

  ContentMarkerState markerFor(ContentItem item) =>
      markers[ContentIdentity.fromItem(item)] ?? const ContentMarkerState();

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) => markerFor(item).completed).length;
    final listened = items.where((item) => markerFor(item).listened).length;
    final favorites = items.where((item) => markerFor(item).favorite).length;
    final dueValue = dueReviewItems.when(
      data: (due) => '${due.length}',
      loading: () => '—',
      error: (error, stackTrace) => '—',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        const _BrandHero(),
        const SizedBox(height: 18),
        _LearningContextCard(contextValue: learningContext),
        const SizedBox(height: 28),
        const _SectionTitle(
          title: 'Continue learning',
          subtitle: 'Pick up from the best next step in your learning path.',
        ),
        const SizedBox(height: 12),
        _ContinueLearningCard(target: continueLearning),
        const SizedBox(height: 30),
        const _SectionTitle(
          title: 'Today',
          subtitle: 'A quick view of your current learning activity.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              icon: Icons.replay_rounded,
              label: 'Due',
              value: dueValue,
              emphasized: true,
            ),
            _StatCard(
              icon: Icons.check_circle_outline_rounded,
              label: 'Completed',
              value: '$completed',
            ),
            _StatCard(
              icon: Icons.headphones_rounded,
              label: 'Listened',
              value: '$listened',
            ),
            _StatCard(
              icon: Icons.favorite_border_rounded,
              label: 'Favorites',
              value: '$favorites',
            ),
          ],
        ),
        const SizedBox(height: 30),
        const _SectionTitle(
          title: 'Quick actions',
          subtitle: 'Choose how you want to practice right now.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context.go('/catalogue'),
              icon: const Icon(Icons.school_outlined),
              label: const Text('Explore learning'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/tests'),
              icon: const Icon(Icons.quiz_outlined),
              label: const Text('Practice test'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/review'),
              icon: const Icon(Icons.replay_outlined),
              label: const Text('Daily review'),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 30),
          const _SectionTitle(
            title: 'Recommended',
            subtitle: 'Useful material from your current catalogue.',
          ),
          const SizedBox(height: 12),
          for (final item in items.take(3)) ...[
            ContentCard(item: item),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.graphic_eq_rounded, color: scheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VoxPrep',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prepare. Practice. Improve.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Professional English and interview practice built around one clear next step.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.target});

  final AsyncValue<ContinueLearningHomeTarget> target;

  @override
  Widget build(BuildContext context) {
    return target.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Your next learning step is temporarily unavailable.'),
        ),
      ),
      data: (value) => Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (value.coverContent case final content?)
              ContentCover(
                content: content,
                revision: value.coverRevision!,
                height: 180,
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR NEXT STEP',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(value.subtitle),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push(value.location),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearningContextCard extends StatelessWidget {
  const _LearningContextCard({required this.contextValue});

  final AsyncValue<LearnerLearningContext?> contextValue;

  @override
  Widget build(BuildContext context) {
    return contextValue.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (error, stack) => Card(
        child: ListTile(
          leading: const Icon(Icons.route_outlined),
          title: const Text('Learning direction unavailable'),
          subtitle: const Text('Choose or change it from Learn.'),
          trailing: TextButton(
            onPressed: () => context.push('/learn/direction'),
            child: const Text('Open'),
          ),
        ),
      ),
      data: (value) {
        if (value == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.route_outlined),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose learning direction',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tell VoxPrep what you are preparing for so the catalogue can focus on the right path.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => context.push('/learn/direction'),
                          child: const Text('Choose'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(Icons.route_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.goalTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(value.verticalTitle),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/learn/direction'),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeLoadError extends StatelessWidget {
  const _HomeLoadError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42),
            SizedBox(height: 12),
            Text(
              'Could not load your learning home.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      child: Card(
        color: emphasized ? scheme.primaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: emphasized ? scheme.onPrimaryContainer : null),
              const SizedBox(height: 14),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
