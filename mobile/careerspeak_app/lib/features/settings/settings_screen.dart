import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_preferences_providers.dart';
import '../../domain/application_preferences.dart';
import 'locale_selection_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(applicationPreferencesProvider);
    final preferences =
        preferencesAsync.asData?.value ?? ApplicationPreferences.defaults;
    final preferencesReady = preferencesAsync.asData != null;
    final preferencesController = ref.read(appPreferencesControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.settings_suggest_outlined),
              label: const Text('System'),
              selected: preferences.theme == AppThemePreference.system,
              onSelected: preferencesReady
                  ? (_) => preferencesController.setTheme(
                      AppThemePreference.system,
                    )
                  : null,
            ),
            ChoiceChip(
              avatar: const Icon(Icons.light_mode_outlined),
              label: const Text('Light'),
              selected: preferences.theme == AppThemePreference.light,
              onSelected: preferencesReady
                  ? (_) =>
                        preferencesController.setTheme(AppThemePreference.light)
                  : null,
            ),
            ChoiceChip(
              avatar: const Icon(Icons.dark_mode_outlined),
              label: const Text('Dark'),
              selected: preferences.theme == AppThemePreference.dark,
              onSelected: preferencesReady
                  ? (_) =>
                        preferencesController.setTheme(AppThemePreference.dark)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Country and language',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        const LocaleSelectionPanel(),
        const SizedBox(height: 20),
        SizedBox(
          width: 280,
          child: DropdownMenu<PreferredEnglishAccent>(
            initialSelection: preferences.preferredAccent,
            enabled: preferencesReady,
            label: const Text('Preferred English accent'),
            expandedInsets: EdgeInsets.zero,
            dropdownMenuEntries: [
              for (final value in PreferredEnglishAccent.values)
                DropdownMenuEntry(value: value, label: value.label),
            ],
            onSelected: preferencesController.setPreferredAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Country controls which locales Backend offers. The selected locale is the single source of truth for hints, explanations, API Accept-Language and localized UI where available.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (preferencesAsync.hasError) ...[
          const SizedBox(height: 8),
          Text(
            'Preferences are unavailable.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 28),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Country: ${preferences.countryCode ?? 'Not selected'}'),
                Text(
                  'Language: ${preferences.selectedLocale.label} (${preferences.selectedLocale.code})',
                ),
                Text(
                  'Direction: ${preferences.selectedLocale.isRtl ? 'RTL' : 'LTR'}',
                ),
                Text(
                  'Accent: ${preferences.preferredAccent?.label ?? 'Default'}',
                ),
                Text('Theme: ${preferences.theme.code}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.accessibility_new_outlined),
          title: Text('Accessibility'),
          subtitle: Text(
            'Text scale, layout direction and reduced-motion preferences follow system settings.',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.storage_outlined),
          title: Text('Storage'),
          subtitle: Text('Offline content is managed by production adapters'),
        ),
      ],
    );
  }
}
