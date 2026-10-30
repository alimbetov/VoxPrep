import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_content_repository.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_card.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(mockContentRepositoryProvider);
    final markers = ref.watch(contentMarkersProvider);
    final due = repository.all
        .where((item) => !(markers[item.code]?.completed ?? false))
        .take(4)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Review', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('${due.length} mock items due for review.'),
        const SizedBox(height: 20),
        for (final item in due) ContentCard(item: item),
      ],
    );
  }
}
