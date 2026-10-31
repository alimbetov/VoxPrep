import 'package:flutter/material.dart';

import '../../core/motion/careerspeak_motion.dart';
import '../../domain/content_marker_state.dart';

class ContentMarkerChips extends StatelessWidget {
  const ContentMarkerChips({required this.state, super.key});

  final ContentMarkerState state;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (state.listened) {
      chips.add(
        const Chip(
          avatar: Icon(Icons.headphones, size: 18),
          label: Text('Listened'),
        ),
      );
    }
    if (state.completed) {
      chips.add(
        const Chip(
          avatar: Icon(Icons.check_circle_outline, size: 18),
          label: Text('Completed'),
        ),
      );
    }
    if (state.favorite) {
      chips.add(
        const Chip(
          avatar: Icon(Icons.favorite_outline, size: 18),
          label: Text('Favorite'),
        ),
      );
    }

    final markerKey = Object.hash(
      state.favorite,
      state.listened,
      state.completed,
    );
    final duration = CareerSpeakMotion.duration(
      context,
      CareerSpeakMotion.standard,
    );

    return AnimatedSize(
      duration: duration,
      curve: CareerSpeakMotion.standardCurve,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: CareerSpeakMotion.standardCurve,
        switchOutCurve: CareerSpeakMotion.standardCurve,
        child: chips.isEmpty
            ? SizedBox.shrink(key: ValueKey<int>(markerKey))
            : Wrap(
                key: ValueKey<int>(markerKey),
                spacing: 8,
                runSpacing: 4,
                children: chips,
              ),
      ),
    );
  }
}
