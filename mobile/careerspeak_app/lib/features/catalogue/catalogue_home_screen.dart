import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/catalogue_payload_providers.dart';
import '../../application/content_delivery/learning_vertical.dart';
import '../../application/content_delivery/universal_catalogue_graph.dart';
import '../../application/content_delivery/vertical_catalogue_presentation.dart';
import 'catalogue_asset_icon.dart';
import 'catalogue_screen.dart';

class CatalogueHomeScreen extends ConsumerWidget {
  const CatalogueHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(currentUniversalCatalogueProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Message('Unable to load catalogue.\n$error'),
      data: (value) {
        if (value == null) {
          return const _Message(
            'No published learning catalogue is available yet.',
          );
        }
        final graph = value.graph;
        final visibleVerticals = _visibleVerticals(graph);
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _CatalogueHeader(showSeeAll: graph.presentation.showSeeAll),
            const SizedBox(height: 24),
            if (visibleVerticals.isEmpty)
              const _Message('No active learning paths.')
            else
              switch (graph.presentation.mode) {
                VerticalCataloguePresentationMode.shelves => _Shelves(
                  graph: graph,
                ),
                VerticalCataloguePresentationMode.carousel => _Carousel(
                  verticals: visibleVerticals,
                ),
                VerticalCataloguePresentationMode.grid => _Grid(
                  verticals: visibleVerticals,
                ),
              },
          ],
        );
      },
    );
  }
}

class _CatalogueHeader extends StatelessWidget {
  const _CatalogueHeader({required this.showSeeAll});

  final bool showSeeAll;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning catalogue',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a learning path.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
    final seeAll = Tooltip(
      message: 'See all learning paths',
      child: TextButton.icon(
        onPressed: () => context.push('/catalogue/all'),
        icon: const Icon(Icons.apps_outlined),
        label: const Text('See all'),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 440 || textScale >= 1.6;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              if (showSeeAll) ...[
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: seeAll),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: copy),
            if (showSeeAll) ...[
              const SizedBox(width: 12),
              seeAll,
            ],
          ],
        );
      },
    );
  }
}

class CatalogueAllScreen extends ConsumerWidget {
  const CatalogueAllScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(currentUniversalCatalogueProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Message('Unable to load catalogue.\n$error'),
      data: (value) {
        if (value == null) {
          return const _Message(
            'No published learning catalogue is available yet.',
          );
        }
        final verticals = _visibleVerticals(value.graph);
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'All learning paths',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            _Grid(verticals: verticals),
          ],
        );
      },
    );
  }
}

List<LearningVerticalProjection> _visibleVerticals(
  UniversalCatalogueGraph graph,
) {
  final activeSections = graph.sections
      .where((section) => section.active)
      .map((section) => section.code)
      .toSet();
  return graph.verticals
      .where(
        (vertical) =>
            vertical.active && activeSections.contains(vertical.sectionCode),
      )
      .toList(growable: false);
}

class _Shelves extends StatelessWidget {
  const _Shelves({required this.graph});

  final UniversalCatalogueGraph graph;

  @override
  Widget build(BuildContext context) {
    final sections = graph.sections.where((item) => item.active).toList();
    final featured = graph.presentation.featuredSectionCode;
    sections.sort((a, b) {
      if (graph.presentation.showFeatured && featured != null) {
        if (a.code == featured && b.code != featured) return -1;
        if (b.code == featured && a.code != featured) return 1;
      }
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.code.compareTo(b.code);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections)
          _Shelf(
            title: section.title,
            description: section.description,
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
  const _Shelf({
    required this.title,
    required this.description,
    required this.verticals,
  });

  final String title;
  final String? description;
  final List<LearningVerticalProjection> verticals;

  @override
  Widget build(BuildContext context) {
    if (verticals.isEmpty) return const SizedBox.shrink();
    final cardHeight = _adaptiveCardHeight(context, base: 190, extraAt2x: 120);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description!),
          ],
          const SizedBox(height: 10),
          SizedBox(
            height: cardHeight,
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
    return SizedBox(
      height: _adaptiveCardHeight(context, base: 250, extraAt2x: 120),
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

class _Grid extends StatelessWidget {
  const _Grid({required this.verticals});

  final List<LearningVerticalProjection> verticals;

  @override
  Widget build(BuildContext context) {
    if (verticals.isEmpty) return const _Message('No active learning paths.');
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 700
            ? 3
            : constraints.maxWidth >= 440
            ? 2
            : 1;
        final aspectRatio = textScale >= 1.8
            ? 0.9
            : textScale >= 1.3
            ? 1.1
            : 1.45;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
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
              CatalogueAssetIcon(assetId: vertical.iconAssetId, size: 32),
              const SizedBox(height: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      vertical.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        vertical.description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
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

class _Message extends StatelessWidget {
  const _Message(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
    );
  }
}

double _adaptiveCardHeight(
  BuildContext context, {
  required double base,
  required double extraAt2x,
}) {
  final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
  return base + ((scale - 1) * extraAt2x);
}
