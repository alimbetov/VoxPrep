import 'package:flutter/material.dart';

import '../../domain/content_marker_state.dart';

class ContentMarkerChips extends StatelessWidget {
  const ContentMarkerChips({required this.state, super.key});

  final ContentMarkerState state;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (state.listened) {
      chips.add(const Chip(
        avatar: Icon(Icons.headphones, size: 18),
        label: Text('Listened'),
      ));
    }
    if (state.completed) {
      chips.add(const Chip(
        avatar: Icon(Icons.check_circle_outline, size: 18),
        label: Text('Completed'),
      ));
    }
    if (state.favorite) {
      chips.add(const Chip(
        avatar: Icon(Icons.favorite_outline, size: 18),
        label: Text('Favorite'),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }
}
