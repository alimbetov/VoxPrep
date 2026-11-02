import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/access_providers.dart';
import '../../app/catalogue_payload_providers.dart';
import '../../app/content_locations.dart';
import '../../app/repository_providers.dart';
import '../../application/content_delivery/collection_access_policy.dart';
import '../../application/content_delivery/learning_vertical.dart';
import '../../application/content_delivery/product_catalog.dart';
import '../../application/content_delivery/universal_catalogue_graph.dart';
import '../../application/ports/universal_catalogue_repository.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../access/full_unlock_screen.dart';
import '../shared/content_cover.dart';

String catalogueVerticalLocation(String code) =>
    '/catalogue/vertical/${Uri.encodeComponent(code)}';

String catalogueGoalLocation(String verticalCode, String goalCode) =>
    '${catalogueVerticalLocation(verticalCode)}/goal/${Uri.encodeComponent(goalCode)}';

String catalogueTrackLocation(
  String verticalCode,
  String goalCode,
  String trackCode,
) =>
    '${catalogueGoalLocation(verticalCode, goalCode)}/track/${Uri.encodeComponent(trackCode)}';

String catalogueCollectionLocation(
  String verticalCode,
  String goalCode,
  String trackCode,
  String collectionCode,
) =>
    '${catalogueTrackLocation(verticalCode, goalCode, trackCode)}/collection/${Uri.encodeComponent(collectionCode)}';

class CatalogueVerticalScreen extends ConsumerWidget {
  const CatalogueVerticalScreen({required this.verticalCode, super.key});

  final String verticalCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _withSnapshot(ref, (snapshot) {
      final graph = snapshot.graph;
      final vertical = _activeVertical(graph, verticalCode);
      if (vertical == null) {
        return const _NotFound(message: 'This learning path is unavailable.');
      }
      final goals = graph.goals
          .where((item) => item.verticalCode == vertical.code && item.active)
          .toList(growable: false);
      return _HierarchyPage(
        eyebrow: 'LEARNING PATH',
        title: vertical.title,
        description: vertical.description,
        emptyMessage: 'No learning goals are available here yet.',
        children: [
          for (final goal in goals)
            _HierarchyCard(
              icon: Icons.flag_outlined,
              title: goal.title,
              description: goal.description,
              actionLabel: 'Explore goal',
              onTap: () =>
                  context.push(catalogueGoalLocation(vertical.code, goal.code)),
            ),
        ],
      );
    });
  }
}

class CatalogueGoalScreen extends ConsumerWidget {
  const CatalogueGoalScreen({
    required this.verticalCode,
    required this.goalCode,
    super.key,
  });

  final String verticalCode;
  final String goalCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _withSnapshot(ref, (snapshot) {
      final graph = snapshot.graph;
      final vertical = _activeVertical(graph, verticalCode);
      if (vertical == null) {
        return const _NotFound(message: 'This learning goal is unavailable.');
      }
      final goal = _activeGoal(graph, vertical.code, goalCode);
      if (goal == null) {
        return const _NotFound(message: 'This learning goal is unavailable.');
      }
      final tracks = graph.tracks
          .where(
            (item) =>
                item.goalCode == goal.code &&
                item.verticalCode == vertical.code &&
                item.active,
          )
          .toList(growable: false);
      return _HierarchyPage(
        eyebrow: vertical.title.toUpperCase(),
        title: goal.title,
        description: goal.description,
        emptyMessage: 'No learning tracks are available for this goal yet.',
        children: [
          for (final track in tracks)
            _HierarchyCard(
              icon: Icons.route_outlined,
              title: track.title,
              description: track.description,
              supportingText: track.levelCode,
              actionLabel: 'View track',
              onTap: () => context.push(
                catalogueTrackLocation(vertical.code, goal.code, track.code),
              ),
            ),
        ],
      );
    });
  }
}

class CatalogueTrackScreen extends ConsumerWidget {
  const CatalogueTrackScreen({
    required this.verticalCode,
    required this.goalCode,
    required this.trackCode,
    super.key,
  });

  final String verticalCode;
  final String goalCode;
  final String trackCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learnerAccess = ref.watch(learnerAccessLevelProvider);
    return _withSnapshot(ref, (snapshot) {
      final graph = snapshot.graph;
      final vertical = _activeVertical(graph, verticalCode);
      if (vertical == null) {
        return const _NotFound(message: 'This learning track is unavailable.');
      }
      final goal = _activeGoal(graph, vertical.code, goalCode);
      if (goal == null) {
        return const _NotFound(message: 'This learning track is unavailable.');
      }
      final track = _activeTrack(graph, vertical.code, goal.code, trackCode);
      if (track == null) {
        return const _NotFound(message: 'This learning track is unavailable.');
      }
      final collections = graph.collections
          .where(
            (item) =>
                item.trackCode == track.code &&
                item.verticalCode == vertical.code &&
                item.active,
          )
          .toList(growable: false);
      return _HierarchyPage(
        eyebrow: goal.title.toUpperCase(),
        title: track.title,
        description: track.description,
        emptyMessage:
            'No learning collections are available for this track yet.',
        children: [
          for (final collection in collections)
            _HierarchyCard(
              icon: Icons.menu_book_outlined,
              title: collection.title,
              description: collection.description,
              supportingText: '${collection.members.length} learning items',
              actionLabel: 'Open collection',
              locked: CollectionAccessPolicy.requiresUnlock(
                learnerAccess: learnerAccess,
                collection: collection,
              ),
              onTap: () {
                final requiresUnlock = CollectionAccessPolicy.requiresUnlock(
                  learnerAccess: learnerAccess,
                  collection: collection,
                );
                context.push(
                  requiresUnlock
                      ? fullUnlockLocation
                      : catalogueCollectionLocation(
                          vertical.code,
                          goal.code,
                          track.code,
                          collection.code,
                        ),
                );
              },
            ),
        ],
      );
    });
  }
}

class CatalogueCollectionScreen extends ConsumerWidget {
  const CatalogueCollectionScreen({
    required this.verticalCode,
    required this.goalCode,
    required this.trackCode,
    required this.collectionCode,
    super.key,
  });

  final String verticalCode;
  final String goalCode;
  final String trackCode;
  final String collectionCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learnerAccess = ref.watch(learnerAccessLevelProvider);
    return _withSnapshot(ref, (snapshot) {
      final graph = snapshot.graph;
      final vertical = _activeVertical(graph, verticalCode);
      if (vertical == null) {
        return const _NotFound(
          message: 'This learning collection is unavailable.',
        );
      }
      final goal = _activeGoal(graph, vertical.code, goalCode);
      if (goal == null) {
        return const _NotFound(
          message: 'This learning collection is unavailable.',
        );
      }
      final track = _activeTrack(graph, vertical.code, goal.code, trackCode);
      if (track == null) {
        return const _NotFound(
          message: 'This learning collection is unavailable.',
        );
      }
      final collection = graph.collections
          .where(
            (item) =>
                item.code == collectionCode &&
                item.trackCode == track.code &&
                item.verticalCode == vertical.code &&
                item.active,
          )
          .firstOrNull;
      if (collection == null) {
        return const _NotFound(
          message: 'This learning collection is unavailable.',
        );
      }
      if (CollectionAccessPolicy.requiresUnlock(
        learnerAccess: learnerAccess,
        collection: collection,
      )) {
        return _FullAccessRequired(collection: collection);
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        children: [
          Text(
            'COLLECTION',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            collection.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            collection.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.format_list_numbered_rounded, size: 18),
              const SizedBox(width: 6),
              Text('${collection.members.length} learning items'),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Your learning sequence',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Work through the lessons and practice tests in order, or open any available step.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          for (final member in collection.members) ...[
            _CollectionMemberCard(member: member),
            const SizedBox(height: 12),
          ],
        ],
      );
    });
  }
}

Widget _withSnapshot(
  WidgetRef ref,
  Widget Function(CurrentUniversalCatalogueSnapshot snapshot) builder,
) {
  final value = ref.watch(currentUniversalCatalogueProvider);
  return value.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stackTrace) => const _CatalogueError(),
    data: (snapshot) =>
        snapshot == null ? const _CatalogueEmpty() : builder(snapshot),
  );
}

LearningVerticalProjection? _activeVertical(
  UniversalCatalogueGraph graph,
  String verticalCode,
) {
  return graph.verticals
      .where((item) => item.code == verticalCode && item.active)
      .firstOrNull;
}

LearningGoalProjection? _activeGoal(
  UniversalCatalogueGraph graph,
  String verticalCode,
  String goalCode,
) {
  return graph.goals
      .where(
        (item) =>
            item.code == goalCode &&
            item.verticalCode == verticalCode &&
            item.active,
      )
      .firstOrNull;
}

LearningTrackProjection? _activeTrack(
  UniversalCatalogueGraph graph,
  String verticalCode,
  String goalCode,
  String trackCode,
) {
  return graph.tracks
      .where(
        (item) =>
            item.code == trackCode &&
            item.goalCode == goalCode &&
            item.verticalCode == verticalCode &&
            item.active,
      )
      .firstOrNull;
}

class _HierarchyPage extends StatelessWidget {
  const _HierarchyPage({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.children,
    required this.emptyMessage,
  });

  final String eyebrow;
  final String title;
  final String description;
  final List<Widget> children;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 26),
        if (children.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Text(emptyMessage),
            ),
          )
        else
          for (final child in children) ...[child, const SizedBox(height: 12)],
      ],
    );
  }
}

class _HierarchyCard extends StatelessWidget {
  const _HierarchyCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.actionLabel,
    this.supportingText,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? supportingText;
  final VoidCallback onTap;
  final String actionLabel;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              child: Text(
                                'FULL',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: scheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(description),
                    if (supportingText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        supportingText!,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          locked
                              ? Icons.lock_outline
                              : Icons.arrow_forward_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          locked ? 'Unlock to continue' : actionLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: scheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionMemberCard extends StatelessWidget {
  const _CollectionMemberCard({required this.member});

  final LearningCollectionMember member;

  @override
  Widget build(BuildContext context) {
    return switch (member.type) {
      LearningCollectionMemberType.content => _ContentCollectionMemberCard(
        member: member,
      ),
      LearningCollectionMemberType.practiceTest => _PracticeTestMemberCard(
        member: member,
      ),
    };
  }
}

class _ContentCollectionMemberCard extends ConsumerWidget {
  const _ContentCollectionMemberCard({required this.member});

  final LearningCollectionMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = member.contentRef!;
    final identity = ContentIdentity(
      code: content.contentCode,
      type: content.contentType,
    );
    final resolved = ref
        .watch(contentByIdentityProvider(identity))
        .asData
        ?.value;
    final exact = resolved?.revision == content.revision ? resolved : null;
    final title = exact?.title ?? _contentTypeLabel(content.contentType);
    final subtitle = exact?.subtitle ?? 'Learning content';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(contentDetailLocation(identity)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentCover(
              content: identity,
              revision: content.revision,
              height: 132,
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepBadge(step: member.position + 1),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.contentType.name.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeTestMemberCard extends ConsumerWidget {
  const _PracticeTestMemberCard({required this.member});

  final LearningCollectionMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = member.practiceTestRef!;
    final test = ref.watch(
      practiceTestByCodeProvider(reference.practiceTestCode),
    );
    final resolved = test.asData?.value;
    final title = resolved?.title ?? 'Practice test';
    final subtitle = resolved == null
        ? 'Check your knowledge before moving on.'
        : '${resolved.questions.length} questions · ${resolved.subtitle}';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(
          '/tests/${Uri.encodeComponent(reference.practiceTestCode)}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepBadge(step: member.position + 1),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRACTICE TEST',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$step',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _contentTypeLabel(ContentType type) {
  return switch (type) {
    ContentType.vocabulary => 'Vocabulary lesson',
    ContentType.interview => 'Interview practice',
    ContentType.topic => 'Learning topic',
    ContentType.shadowing => 'Shadowing practice',
    ContentType.phrase => 'Useful phrase',
  };
}

class _FullAccessRequired extends StatelessWidget {
  const _FullAccessRequired({required this.collection});

  final LearningCollectionProjection collection;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text('FULL'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unlock this learning collection',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${collection.title} is included with VoxPrep Full.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.push(fullUnlockLocation),
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Unlock Full VoxPrep'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogueEmpty extends StatelessWidget {
  const _CatalogueEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 42),
            SizedBox(height: 12),
            Text('No learning catalogue is available yet.'),
          ],
        ),
      ),
    );
  }
}

class _CatalogueError extends StatelessWidget {
  const _CatalogueError();

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
            Text('Could not load the learning catalogue.'),
            SizedBox(height: 6),
            Text('Check your connection and try again.'),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
