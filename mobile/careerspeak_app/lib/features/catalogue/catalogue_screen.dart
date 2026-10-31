import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/catalogue_payload_providers.dart';
import '../../app/content_locations.dart';
import '../../application/content_delivery/learning_vertical.dart';
import '../../application/content_delivery/product_catalog.dart';
import '../../application/content_delivery/universal_catalogue_graph.dart';
import '../../application/content_delivery/vertical_catalogue_presentation.dart';
import '../../application/ports/universal_catalogue_repository.dart';
import '../../domain/content_identity.dart';

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

class CatalogueScreen extends ConsumerWidget {
  const CatalogueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(currentUniversalCatalogueProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _CatalogueError(error: error),
      data: (value) {
        if (value == null) {
          return const _CatalogueEmpty();
        }
        return _CatalogueHome(snapshot: value);
      },
    );
  }
}

class CatalogueVerticalScreen extends ConsumerWidget {
  const CatalogueVerticalScreen({required this.verticalCode, super.key});

  final String verticalCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _withSnapshot(
      ref,
      (snapshot) {
        final graph = snapshot.graph;
        final vertical = graph.verticals.where(
          (item) => item.code == verticalCode && item.active,
        ).firstOrNull;
        if (vertical == null) {
          return const _NotFound(message: 'Learning vertical is unavailable.');
        }
        final goals = graph.goals
            .where((item) => item.verticalCode == vertical.code && item.active)
            .toList(growable: false);
        return _HierarchyPage(
          title: vertical.title,
          description: vertical.description,
          children: [
            for (final goal in goals)
              _HierarchyCard(
                title: goal.title,
                description: goal.description,
                onTap: () => context.push(
                  catalogueGoalLocation(vertical.code, goal.code),
                ),
              ),
          ],
          emptyMessage: 'No learning goals are published for this vertical.',
        );
      },
    );
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
    return _withSnapshot(
      ref,
      (snapshot) {
        final graph = snapshot.graph;
        final goal = graph.goals.where(
          (item) =>
              item.code == goalCode &&
              item.verticalCode == verticalCode &&
              item.active,
        ).firstOrNull;
        if (goal == null) {
          return const _NotFound(message: 'Learning goal is unavailable.');
        }
        final tracks = graph.tracks
            .where(
              (item) =>
                  item.goalCode == goal.code &&
                  item.verticalCode == verticalCode &&
                  item.active,
            )
            .toList(growable: false);
        return _HierarchyPage(
          title: goal.title,
          description: goal.description,
          children: [
            for (final track in tracks)
              _HierarchyCard(
                title: track.title,
                description: track.description,
                supportingText: track.levelCode,
                onTap: () => context.push(
                  catalogueTrackLocation(verticalCode, goal.code, track.code),
                ),
              ),
          ],
          emptyMessage: 'No learning tracks are published for this goal.',
        );
      },
    );
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
    return _withSnapshot(
      ref,
      (snapshot) {
        final graph = snapshot.graph;
        final track = graph.tracks.where(
          (item) =>
              item.code == trackCode &&
              item.goalCode == goalCode &&
              item.verticalCode == verticalCode &&
              item.active,
        ).firstOrNull;
        if (track == null) {
          return const _NotFound(message: 'Learning track is unavailable.');
        }
        final collections = graph.collections
            .where(
              (item) =>
                  item.trackCode == track.code &&
                  item.verticalCode == verticalCode &&
                  item.active,
            )
            .toList(growable: false);
        return _HierarchyPage(
          title: track.title,
          description: track.description,
          children: [
            for (final collection in collections)
              _HierarchyCard(
                title: collection.title,
                description: collection.description,
                supportingText: '${collection.members.length} items',
                onTap: () => context.push(
                  catalogueCollectionLocation(
                    verticalCode,
                    goalCode,
                    track.code,
                    collection.code,
                  ),
                ),
              ),
          ],
          emptyMessage: 'No learning collections are published for this track.',
        );
      },
    );
  }
}

class CatalogueCollectionScreen extends ConsumerWidget {
  const CatalogueCollectionScreen({
    required this.verticalCode,
    required this.trackCode,
    required this.collectionCode,
    super.key,
  });

  final String verticalCode;
  final String trackCode;
  final String collectionCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _withSnapshot(
      ref,
      (snapshot) {
        final collection = snapshot.graph.collections.where(
          (item) =>
              item.code == collectionCode &&
              item.trackCode == trackCode &&
              item.verticalCode == verticalCode &&
              item.active,
        ).firstOrNull;
        if (collection == null) {
          return const _NotFound(message: 'Learning collection is unavailable.');
        }
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              collection.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(collection.description),
            const SizedBox(height: 24),
            Text('Learning sequence', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final member in collection.members)
              _CollectionMemberCard(member: member),
          ],
        );
      },
    );
  }
}

Widget _withSnapshot(
  WidgetRef ref,
  Widget Function(CurrentUniversalCatalogueSnapshot snapshot) builder,
) {
  final value = ref.watch(currentUniversalCatalogueProvider);
  return value.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stackTrace) => _CatalogueError(error: error),
    data: (snapshot) => snapshot == null
        ? const _CatalogueEmpty()
        : builder(snapshot),
  );
}

class _CatalogueHome extends StatelessWidget {
  const _CatalogueHome({required this.snapshot});

  final CurrentUniversalCatalogueSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final graph = snapshot.graph;
    final activeVerticals = graph.verticals.where((item) => item.active).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Learning catalogue', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Choose a learning path.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        switch (graph.presentation.mode) {
          VerticalCataloguePresentationMode.shelves =>
            _Shelves(graph: graph),
          VerticalCataloguePresentationMode.carousel =>
            _Carousel(verticals: activeVerticals),
          VerticalCataloguePresentationMode.grid =>
            _VerticalGrid(verticals: activeVerticals),
        },
      ],
    );
  }
}

class _Shelves extends StatelessWidget {
  const _Shelves({required this.graph});

  final UniversalCatalogueGraph graph;

  @override
  Widget build(BuildContext context) {
    final sections = graph.sections.where((item) => item.active).toList();
    final featured = graph.presentation.featuredSectionCode;
    if (graph.presentation.showFeatured && featured != null) {
      sections.sort((a, b) {
        if (a.code == featured) return -1;
        if (b.code == featured) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections)
          _Shelf(
            section: section,
            verticals: graph.verticals
                .where(
                  (item) => item.active && item.sectionCode == section.code,
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.section, required this.verticals});

  final VerticalSectionProjection section;
  final List<LearningVerticalProjection> verticals;

  @override
  Widget build(BuildContext context) {
    if (verticals.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.titleLarge),
          if (section.description != null) ...[
            const SizedBox(height: 4),
            Text(section.description!),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: verticals.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 260,
                child: _VerticalCard(vertical: verticals[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({required this.verticals});

  final List<LearningVerticalProjection> verticals;

  @override
  Widget build(BuildContext context) {
    if (verticals.isEmpty) return const _CatalogueEmpty();
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: verticals.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _VerticalCard(vertical: verticals[index]),
        ),
      ),
    );
  }
}

class _VerticalGrid extends StatelessWidget {
  const _VerticalGrid({required this.verticals});

  final List<LearningVerticalProjection> verticals;

  @override
  Widget build(BuildContext context) {
    if (verticals.isEmpty) return const _CatalogueEmpty();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 700
                ? 3
                : constraints.maxWidth >= 440
                    ? 2
                    : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemCount: verticals.length,
          itemBuilder: (context, index) =>
              _VerticalCard(vertical: verticals[index]),
        );
      },
    );
  }
}

class _VerticalCard extends StatelessWidget {
  const _VerticalCard({required this.vertical});

  final LearningVerticalProjection vertical;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(catalogueVerticalLocation(vertical.code)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.school_outlined, size: 30),
              const Spacer(),
              Text(vertical.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                vertical.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HierarchyPage extends StatelessWidget {
  const _HierarchyPage({
    required this.title,
    required this.description,
    required this.children,
    required this.emptyMessage,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(description),
        const SizedBox(height: 24),
        if (children.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(emptyMessage),
            ),
          )
        else
          ...children,
      ],
    );
  }
}

class _HierarchyCard extends StatelessWidget {
  const _HierarchyCard({
    required this.title,
    required this.description,
    required this.onTap,
    this.supportingText,
  });

  final String title;
  final String description;
  final String? supportingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description),
            if (supportingText != null) ...[
              const SizedBox(height: 6),
              Text(supportingText!),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
      LearningCollectionMemberType.content => _HierarchyCard(
          title: member.contentRef!.contentCode,
          description:
              '${member.contentRef!.contentType.name} · revision ${member.contentRef!.revision}',
          supportingText: 'Step ${member.position + 1}',
          onTap: () => context.push(
            contentDetailLocation(
              ContentIdentity(
                code: member.contentRef!.contentCode,
                type: member.contentRef!.contentType,
              ),
            ),
          ),
        ),
      LearningCollectionMemberType.practiceTest => _HierarchyCard(
          title: member.practiceTestRef!.practiceTestCode,
          description: 'Practice test · revision ${member.practiceTestRef!.revision}',
          supportingText: 'Step ${member.position + 1}',
          onTap: () => context.push(
            '/tests/${Uri.encodeComponent(member.practiceTestRef!.practiceTestCode)}',
          ),
        ),
    };
  }
}

class _CatalogueEmpty extends StatelessWidget {
  const _CatalogueEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No published learning catalogue is available yet.'),
      ),
    );
  }
}

class _CatalogueError extends StatelessWidget {
  const _CatalogueError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Unable to load the learning catalogue.\n$error'),
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
        child: Text(message),
      ),
    );
  }
}
