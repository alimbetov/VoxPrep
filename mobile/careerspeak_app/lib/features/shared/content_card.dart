import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/content_locations.dart';
import '../../app/learner_state_providers.dart';
import '../../core/localization/careerspeak_learning_text.dart';
import '../../core/motion/careerspeak_motion.dart';
import '../../domain/content_identity.dart';
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
    final identity = ContentIdentity.fromItem(item);
    final markers = ref.watch(contentMarkersProvider);
    final markerState = markers.when(
      data: (value) => value[identity] ?? const ContentMarkerState(),
      loading: () => const ContentMarkerState(),
      error: (error, stackTrace) => const ContentMarkerState(),
    );
    final scheme = Theme.of(context).colorScheme;
    final duration = CareerSpeakMotion.duration(
      context,
      CareerSpeakMotion.standard,
    );

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: selected ? scheme.secondaryContainer : scheme.surfaceContainerLow,
      ),
      duration: duration,
      curve: CareerSpeakMotion.standardCurve,
      builder: (context, color, child) {
        return Card(color: color, clipBehavior: Clip.antiAlias, child: child);
      },
      child: InkWell(
        onTap: onTap ?? () => context.push(contentDetailLocation(identity)),
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
                    CareerSpeakLearningText(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    CareerSpeakLearningText(item.subtitle),
                    const SizedBox(height: 10),
                    ContentMarkerChips(state: markerState),
                  ],
                ),
              ),
              IconButton(
                tooltip: markerState.favorite
                    ? 'Remove favorite'
                    : 'Add favorite',
                onPressed: () async {
                  final result = await ref
                      .read(learnerStateRepositoryProvider)
                      .setFavorite(identity, favorite: !markerState.favorite);
                  try {
                    result.getOrThrow();
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to update favorite: $error'),
                      ),
                    );
                  }
                },
                icon: AnimatedSwitcher(
                  duration: CareerSpeakMotion.duration(
                    context,
                    CareerSpeakMotion.fast,
                  ),
                  switchInCurve: CareerSpeakMotion.standardCurve,
                  switchOutCurve: CareerSpeakMotion.standardCurve,
                  child: Icon(
                    markerState.favorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    key: ValueKey<bool>(markerState.favorite),
                  ),
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
