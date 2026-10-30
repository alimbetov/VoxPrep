import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'window_size_class.dart';

class CareerSpeakAdaptiveScaffold extends StatelessWidget {
  const CareerSpeakAdaptiveScaffold({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const _destinations = <_Destination>[
    _Destination('/', 'Home', Icons.home_outlined, Icons.home),
    _Destination('/learn', 'Learn', Icons.school_outlined, Icons.school),
    _Destination('/tests', 'Tests', Icons.quiz_outlined, Icons.quiz),
    _Destination('/review', 'Review', Icons.replay_outlined, Icons.replay),
    _Destination('/settings', 'Settings', Icons.settings_outlined, Icons.settings),
  ];

  int get _selectedIndex {
    if (location.startsWith('/content/')) return 1;
    final index = _destinations.indexWhere(
      (destination) => destination.path != '/' && location.startsWith(destination.path),
    );
    return index < 0 ? 0 : index;
  }

  void _go(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final windowClass = windowSizeClassFor(width);
    final compact = windowClass == CareerSpeakWindowSizeClass.compact;
    final large = windowClass == CareerSpeakWindowSizeClass.large;

    if (compact) {
      return Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => _go(context, index),
          destinations: [
            for (final destination in _destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              extended: large,
              labelType: large ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              onDestinationSelected: (index) => _go(context, index),
              destinations: [
                for (final destination in _destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(
    this.path,
    this.label,
    this.icon,
    this.selectedIcon,
  );

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
