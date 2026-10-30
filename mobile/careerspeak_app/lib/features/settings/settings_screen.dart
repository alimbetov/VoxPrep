import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/careerspeak_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.settings_suggest_outlined),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Dark'),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (selection) => ref
              .read(themeModeProvider.notifier)
              .setMode(selection.first),
        ),
        const SizedBox(height: 28),
        const ListTile(
          leading: Icon(Icons.translate),
          title: Text('UI language'),
          subtitle: Text('English · mock setting'),
        ),
        const ListTile(
          leading: Icon(Icons.subtitles_outlined),
          title: Text('Translation language'),
          subtitle: Text('Русский · mock setting'),
        ),
        const ListTile(
          leading: Icon(Icons.storage_outlined),
          title: Text('Storage'),
          subtitle: Text('Mock data only · no files downloaded'),
        ),
      ],
    );
  }
}
