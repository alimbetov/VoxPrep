import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_preferences_providers.dart';
import '../../app/content_sync_providers.dart';
import '../../app/locale_configuration_providers.dart';
import '../../application/content_sync/sync_models.dart';
import '../../application/result/result.dart';
import '../../domain/application_preferences.dart';
import '../../domain/locale_configuration.dart';

class LocaleSelectionPanel extends ConsumerStatefulWidget {
  const LocaleSelectionPanel({
    this.primaryActionLabel = 'Apply language',
    this.onSaved,
    super.key,
  });

  final String primaryActionLabel;
  final VoidCallback? onSaved;

  @override
  ConsumerState<LocaleSelectionPanel> createState() =>
      _LocaleSelectionPanelState();
}

class _LocaleSelectionPanelState extends ConsumerState<LocaleSelectionPanel> {
  String? _countryCode;
  String? _localeCode;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final preferencesAsync = ref.watch(applicationPreferencesProvider);
    final preferences =
        preferencesAsync.asData?.value ?? ApplicationPreferences.defaults;
    final countryCode = _countryCode ?? preferences.countryCode;
    final country = CountryService().findByCode(countryCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Country', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _saving ? null : () => _selectCountry(context),
            icon: Text(
              country?.flagEmoji ?? '🌍',
              style: const TextStyle(fontSize: 22),
            ),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                country == null
                    ? 'Select country'
                    : '${country.name} (${country.countryCode})',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (countryCode == null)
          Text(
            'Choose your country to load the languages enabled by Backend.',
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          _LocaleConfigurationView(
            countryCode: countryCode,
            requestedLocaleCode: _localeCode,
            persistedLocale: preferences.countryCode == countryCode
                ? preferences.selectedLocale
                : null,
            saving: _saving,
            primaryActionLabel: widget.primaryActionLabel,
            onLocaleChanged: (value) => setState(() => _localeCode = value),
            onSave: _save,
          ),
      ],
    );
  }

  void _selectCountry(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      showSearch: true,
      showDragHandle: true,
      onSelect: (country) {
        setState(() {
          _countryCode = country.countryCode.toUpperCase();
          _localeCode = null;
        });
      },
    );
  }

  Future<void> _save(
    CountryLocaleConfiguration configuration,
    AppTranslationLocale locale,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await ref
        .read(appPreferencesControllerProvider)
        .setLocaleSelection(
          countryCode: configuration.countryCode,
          locale: locale,
        );
    if (!mounted) return;

    switch (result) {
      case Success<void>():
        final sync = await ref
            .read(preferenceAwareContentSyncProvider)
            .synchronize(
              runId: 'locale-${DateTime.now().toUtc().microsecondsSinceEpoch}',
              trigger: SyncTrigger.localeChange,
            );
        if (!mounted) return;
        setState(() => _saving = false);
        if (sync case FailureResult(:final failure)) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.message)));
        }
        widget.onSaved?.call();
      case FailureResult<void>(:final failure):
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _LocaleConfigurationView extends ConsumerWidget {
  const _LocaleConfigurationView({
    required this.countryCode,
    required this.requestedLocaleCode,
    required this.persistedLocale,
    required this.saving,
    required this.primaryActionLabel,
    required this.onLocaleChanged,
    required this.onSave,
  });

  final String countryCode;
  final String? requestedLocaleCode;
  final AppTranslationLocale? persistedLocale;
  final bool saving;
  final String primaryActionLabel;
  final ValueChanged<String?> onLocaleChanged;
  final Future<void> Function(
    CountryLocaleConfiguration configuration,
    AppTranslationLocale locale,
  )
  onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configurationAsync = ref.watch(
      countryLocaleConfigurationProvider(countryCode),
    );

    return configurationAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stackTrace) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Languages could not be loaded from Backend.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                ref.invalidate(countryLocaleConfigurationProvider(countryCode)),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
      data: (configuration) {
        final persisted = persistedLocale;
        final selectedCode =
            requestedLocaleCode ??
            (persisted != null && configuration.supports(persisted)
                ? persisted.code
                : configuration.defaultLocale.code);
        final selected = _findOption(configuration.locales, selectedCode);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('$countryCode:$selectedCode'),
              initialValue: selected?.locale.code,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final option in configuration.locales)
                  DropdownMenuItem<String>(
                    value: option.locale.code,
                    child: Text('${option.label} (${option.locale.code})'),
                  ),
              ],
              onChanged: saving ? null : onLocaleChanged,
            ),
            const SizedBox(height: 8),
            Text(
              'This locale is used for hints, explanations and localized UI where available. English learning content remains canonical.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: saving || selected == null
                  ? null
                  : () => onSave(configuration, selected.locale),
              child: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(primaryActionLabel),
            ),
          ],
        );
      },
    );
  }
}

SupportedLocaleOption? _findOption(
  List<SupportedLocaleOption> options,
  String code,
) {
  for (final option in options) {
    if (option.locale.code == code) return option;
  }
  return null;
}
