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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Personalize how VoxPrep looks, sounds and supports your learning.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
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
        const SizedBox(height: 30),
        Text(
          'Country and language',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the language VoxPrep should use for explanations and learning support.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        const LocaleSelectionPanel(),
        const SizedBox(height: 24),
        Text('Audio', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          width: 320,
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
        const SizedBox(height: 30),
        Text('Your preferences', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PreferenceRow(
                  icon: Icons.public_outlined,
                  label: 'Country',
                  value: preferences.countryCode ?? 'Not selected',
                ),
                const SizedBox(height: 14),
                _PreferenceRow(
                  icon: Icons.translate_rounded,
                  label: 'Language',
                  value:
                      '${preferences.selectedLocale.label} (${preferences.selectedLocale.code})',
                ),
                const SizedBox(height: 14),
                _PreferenceRow(
                  icon: Icons.record_voice_over_outlined,
                  label: 'Accent',
                  value: preferences.preferredAccent?.label ?? 'Default',
                ),
                const SizedBox(height: 14),
                _PreferenceRow(
                  icon: Icons.palette_outlined,
                  label: 'Theme',
                  value: preferences.theme.code,
                ),
              ],
            ),
          ),
        ),
        if (preferencesAsync.hasError) ...[
          const SizedBox(height: 10),
          Text(
            'Some preferences are temporarily unavailable.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 28),
        const Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.accessibility_new_outlined),
                title: Text('Accessibility'),
                subtitle: Text(
                  'Text size, layout direction and reduced motion follow your device settings.',
                ),
              ),
              Divider(height: 1),
              ListTile(
                leading: Icon(Icons.offline_pin_outlined),
                title: Text('Offline learning'),
                subtitle: Text(
                  'Downloaded learning media remains available when your device is offline.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
