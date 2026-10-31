import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_preferences_providers.dart';
import '../../app/mock_visual_preferences.dart';
import '../../domain/application_preferences.dart';
import 'catalogue_source_settings_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(applicationPreferencesProvider);
    final preferences =
        preferencesAsync.asData?.value ?? ApplicationPreferences.defaults;
    final preferencesReady = preferencesAsync.asData != null;
    final preferencesController = ref.read(appPreferencesControllerProvider);
    final visual = ref.watch(mockVisualPreferencesProvider);
    final visualController = ref.read(mockVisualPreferencesProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        Text('Catalogue source', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const CatalogueSourceSettingsTile(),
        const SizedBox(height: 28),
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
        Text('Language', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 280,
              child: DropdownMenu<AppUiLocale>(
                initialSelection: preferences.uiLocale,
                enabled: preferencesReady,
                label: const Text('UI language'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (final value in AppUiLocale.values)
                    DropdownMenuEntry(value: value, label: value.label),
                ],
                onSelected: (value) {
                  if (value != null) {
                    preferencesController.setUiLocale(value);
                  }
                },
              ),
            ),
            SizedBox(
              width: 280,
              child: DropdownMenu<AppTranslationLocale>(
                initialSelection: preferences.translationLocale,
                enabled: preferencesReady,
                label: const Text('Translation language'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (final value in AppTranslationLocale.values)
                    DropdownMenuEntry(value: value, label: value.label),
                ],
                onSelected: (value) {
                  if (value != null) {
                    preferencesController.setTranslationLocale(value);
                  }
                },
              ),
            ),
            SizedBox(
              width: 280,
              child: DropdownMenu<PreferredEnglishAccent>(
                initialSelection: preferences.preferredAccent,
                enabled: preferencesReady,
                label: const Text('Preferred accent'),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  for (final value in PreferredEnglishAccent.values)
                    DropdownMenuEntry(value: value, label: value.label),
                ],
                onSelected: preferencesController.setPreferredAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Locale preferences persist BCP-47 codes. English remains the learning language; the backend SupportedLocale catalog is authoritative for translation availability.',
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
        Text(
          'Accessibility preview',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text('Text scale', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in MockTextScalePreview.values)
              ChoiceChip(
                label: Text(value.label),
                selected: visual.textScale == value,
                onSelected: (_) => visualController.setTextScale(value),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Text scale, RTL and reduced-motion controls are structural qualification previews; they are not persisted product preferences.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.format_textdirection_r_to_l),
          title: const Text('RTL layout preview'),
          subtitle: const Text(
            'Flip the application shell while canonical English learning text stays LTR.',
          ),
          value: visual.rtlPreview,
          onChanged: visualController.setRtlPreview,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.motion_photos_off_outlined),
          title: const Text('Reduced motion preview'),
          subtitle: const Text(
            'Disable non-essential route, card and marker transitions.',
          ),
          value: visual.reducedMotionPreview,
          onChanged: visualController.setReducedMotionPreview,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'UI: ${preferences.uiLocale.label} (${preferences.uiLocale.code})',
                ),
                Text(
                  'Translation: ${preferences.translationLocale.label} (${preferences.translationLocale.code})',
                ),
                Text(
                  'Direction: ${preferences.uiLocale.isRtl ? 'RTL' : 'LTR'}',
                ),
                Text(
                  'Accent: ${preferences.preferredAccent?.label ?? 'Default'}',
                ),
                Text('Theme: ${preferences.theme.code}'),
                Text('Text scale preview: ${visual.textScale.label}'),
                Text(
                  'Reduced motion preview: ${visual.reducedMotionPreview ? 'On' : 'Off'}',
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
          subtitle: Text('Offline content is managed by production adapters'),
        ),
      ],
    );
  }
}
