import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/repository_providers.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../content/content_detail_panel.dart';
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
  String? selectedCode;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(contentRepositoryProvider);
    final markers = ref.watch(contentMarkersProvider);
    final filtered = repository.all.where((item) {
      final marker = markers[item.code] ?? const ContentMarkerState();
      final normalizedQuery = query.toLowerCase();
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(normalizedQuery) ||
          item.subtitle.toLowerCase().contains(normalizedQuery);
      if (!matchesQuery) return false;

      return switch (filter) {
        _LearnFilter.all => true,
        _LearnFilter.favorites => marker.favorite,
        _LearnFilter.notListened => !marker.listened,
        _LearnFilter.notCompleted => !marker.completed,
      };
    }).toList();

    final wide = MediaQuery.sizeOf(context).width >= 840;
    if (!wide) {
      return _CatalogList(
        filtered: filtered,
        filter: filter,
        query: query,
        onQueryChanged: (value) => setState(() => query = value.trim()),
        onFilterChanged: (value) => setState(() => filter = value),
      );
    }

    final selectedItem = _effectiveSelection(filtered);
    final catalogueWidth =
        MediaQuery.sizeOf(context).width >= 1200 ? 420.0 : 360.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: catalogueWidth,
          child: _CatalogList(
            filtered: filtered,
            filter: filter,
            query: query,
            selectedCode: selectedItem?.code,
            onQueryChanged: (value) => setState(() => query = value.trim()),
            onFilterChanged: (value) => setState(() => filter = value),
            onItemSelected: (item) => setState(() => selectedCode = item.code),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selectedItem == null
              ? const Center(child: Text('Select learning content.'))
              : ContentDetailPanel(item: selectedItem),
        ),
      ],
    );
  }

  ContentItem? _effectiveSelection(List<ContentItem> filtered) {
    if (filtered.isEmpty) return null;
    if (selectedCode == null) return filtered.first;
    for (final item in filtered) {
      if (item.code == selectedCode) return item;
    }
    return filtered.first;
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.filtered,
    required this.filter,
    required this.query,
    required this.onQueryChanged,
    required this.onFilterChanged,
    this.selectedCode,
    this.onItemSelected,
  });

  final List<ContentItem> filtered;
  final _LearnFilter filter;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_LearnFilter> onFilterChanged;
  final String? selectedCode;
  final ValueChanged<ContentItem>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Learn', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        SearchBar(
          hintText: 'Search vocabulary, interview, topics…',
          leading: const Icon(Icons.search),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: filter == _LearnFilter.all,
              onSelected: (_) => onFilterChanged(_LearnFilter.all),
            ),
            FilterChip(
              label: const Text('Favorites'),
              selected: filter == _LearnFilter.favorites,
              onSelected: (_) => onFilterChanged(_LearnFilter.favorites),
            ),
            FilterChip(
              label: const Text('Not listened'),
              selected: filter == _LearnFilter.notListened,
              onSelected: (_) => onFilterChanged(_LearnFilter.notListened),
            ),
            FilterChip(
              label: const Text('Not completed'),
              selected: filter == _LearnFilter.notCompleted,
              onSelected: (_) => onFilterChanged(_LearnFilter.notCompleted),
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
          for (final item in filtered)
            ContentCard(
              item: item,
              selected: item.code == selectedCode,
              onTap:
                  onItemSelected == null ? null : () => onItemSelected!(item),
            ),
      ],
    );
  }
}
