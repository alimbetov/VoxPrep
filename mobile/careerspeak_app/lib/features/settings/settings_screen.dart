import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/mock_visual_preferences.dart';
import '../../app/theme/careerspeak_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final visual = ref.watch(mockVisualPreferencesProvider);
    final visualController = ref.read(mockVisualPreferencesProvider.notifier);

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
        Text('Language', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 280,
              child: DropdownMenu<MockUiLanguage>(
                initialSelection: visual.uiLanguage,
                label: const Text('UI language'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (final value in MockUiLanguage.values)
                    DropdownMenuEntry(value: value, label: value.label),
                ],
                onSelected: (value) {
                  if (value != null) visualController.setUiLanguage(value);
                },
              ),
            ),
            SizedBox(
              width: 280,
              child: DropdownMenu<MockTranslationLanguage>(
                initialSelection: visual.translationLanguage,
                label: const Text('Translation language'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (final value in MockTranslationLanguage.values)
                    DropdownMenuEntry(value: value, label: value.label),
                ],
                onSelected: (value) {
                  if (value != null) {
                    visualController.setTranslationLanguage(value);
                  }
                },
              ),
            ),
            SizedBox(
              width: 280,
              child: DropdownMenu<MockAccent>(
                initialSelection: visual.accent,
                label: const Text('Preferred accent'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (final value in MockAccent.values)
                    DropdownMenuEntry(value: value, label: value.label),
                ],
                onSelected: (value) {
                  if (value != null) visualController.setAccent(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'P1 keeps visible strings in English. These selectors qualify layout and state only; ARB localization arrives after mock acceptance.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 28),
        Text('Accessibility preview', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.text_fields),
          title: const Text('Large text preview'),
          subtitle: const Text('Render app content at 1.6× text scale.'),
          value: visual.largeTextPreview,
          onChanged: visualController.setLargeTextPreview,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.format_textdirection_r_to_l),
          title: const Text('RTL layout preview'),
          subtitle: const Text('Flip layout direction while keeping mock English strings.'),
          value: visual.rtlPreview,
          onChanged: visualController.setRtlPreview,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Preview', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('UI: ${visual.uiLanguage.label}'),
                Text('Translation: ${visual.translationLanguage.label}'),
                Text('Accent: ${visual.accent.label}'),
                const SizedBox(height: 12),
                const Text(
                  'English learning text stays LTR by contract even when a future localized shell is RTL. The current toggle is a structural stress test for the mock UI.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.storage_outlined),
          title: Text('Storage'),
          subtitle: Text('Mock data only · no files downloaded'),
        ),
      ],
    );
  }
}
