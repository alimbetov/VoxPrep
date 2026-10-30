import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_content_repository.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_card.dart';

enum _LearnFilter { all, favorites, notListened, notCompleted }

class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  _LearnFilter filter = _LearnFilter.all;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(mockContentRepositoryProvider);
    final markers = ref.watch(contentMarkersProvider);

    final filtered = repository.all.where((item) {
      final marker = markers[item.code] ?? const ContentMarkerState();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(query.toLowerCase());
      if (!matchesQuery) return false;

      return switch (filter) {
        _LearnFilter.all => true,
        _LearnFilter.favorites => marker.favorite,
        _LearnFilter.notListened => !marker.listened,
        _LearnFilter.notCompleted => !marker.completed,
      };
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Learn', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        SearchBar(
          hintText: 'Search vocabulary, interview, topics…',
          leading: const Icon(Icons.search),
          onChanged: (value) => setState(() => query = value.trim()),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: filter == _LearnFilter.all,
              onSelected: (_) => setState(() => filter = _LearnFilter.all),
            ),
            FilterChip(
              label: const Text('Favorites'),
              selected: filter == _LearnFilter.favorites,
              onSelected: (_) => setState(() => filter = _LearnFilter.favorites),
            ),
            FilterChip(
              label: const Text('Not listened'),
              selected: filter == _LearnFilter.notListened,
              onSelected: (_) => setState(() => filter = _LearnFilter.notListened),
            ),
            FilterChip(
              label: const Text('Not completed'),
              selected: filter == _LearnFilter.notCompleted,
              onSelected: (_) => setState(() => filter = _LearnFilter.notCompleted),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text('No mock content matches this filter.')),
          )
        else
          for (final item in filtered) ContentCard(item: item),
      ],
    );
  }
}
