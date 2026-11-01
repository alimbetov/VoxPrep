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
      error: (error, stackTrace) => _HomeLoadError(error: error),
      data: (page) => markers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _HomeLoadError(error: error),
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
      padding: const EdgeInsets.all(24),
      children: [
        Text('CareerSpeak', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Professional English, IELTS and interview practice.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        _LearningContextCard(contextValue: learningContext),
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
            _StatCard(
              icon: Icons.replay_outlined,
              label: 'Due',
              value: dueValue,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Continue learning',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        _ContinueLearningCard(target: continueLearning),
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
              onPressed: () => context.go('/catalogue'),
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
          child: Text('Continue learning is temporarily unavailable.'),
        ),
      ),
      data: (value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(value.subtitle),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.push(value.location),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue'),
              ),
            ],
          ),
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
            child: ListTile(
              leading: const Icon(Icons.route_outlined),
              title: const Text('Choose learning direction'),
              subtitle: const Text(
                'Select a professional area and goal to personalize your learning context.',
              ),
              trailing: FilledButton.tonal(
                onPressed: () => context.push('/learn/direction'),
                child: const Text('Choose'),
              ),
            ),
          );
        }

        return Card(
          child: ListTile(
            leading: const Icon(Icons.route_outlined),
            title: Text(value.goalTitle),
            subtitle: Text(value.verticalTitle),
            trailing: TextButton(
              onPressed: () => context.push('/learn/direction'),
              child: const Text('Change'),
            ),
          ),
        );
      },
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
