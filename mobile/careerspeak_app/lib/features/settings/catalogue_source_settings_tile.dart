import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/application_bootstrap_providers.dart';
import '../../app/catalogue_payload_providers.dart';
import '../../app/catalogue_source_providers.dart';
import '../../application/result/result.dart';
import '../../domain/catalogue_source_mode.dart';

class CatalogueSourceSettingsTile extends ConsumerStatefulWidget {
  const CatalogueSourceSettingsTile({super.key});

  @override
  ConsumerState<CatalogueSourceSettingsTile> createState() =>
      _CatalogueSourceSettingsTileState();
}

class _CatalogueSourceSettingsTileState
    extends ConsumerState<CatalogueSourceSettingsTile> {
  bool _changing = false;
  String? _error;

  Future<void> _setDemo(bool enabled) async {
    if (_changing) return;
    setState(() {
      _changing = true;
      _error = null;
    });

    final mode = enabled
        ? CatalogueSourceMode.demo
        : CatalogueSourceMode.production;
    final saved = await ref
        .read(catalogueSourceModeControllerProvider)
        .setMode(mode);

    if (!mounted) return;
    if (saved case FailureResult<void>(:final failure)) {
      setState(() {
        _error = failure.message;
        _changing = false;
      });
      return;
    }

    try {
      ref.invalidate(applicationBootstrapProvider);
      final bootstrap = await ref.read(applicationBootstrapProvider.future);
      if (bootstrap case FailureResult(:final failure)) {
        setState(() => _error = failure.message);
      }
      ref.invalidate(currentUniversalCatalogueProvider);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _changing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(catalogueSourceModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.science_outlined),
          title: const Text('Demo catalogue mode'),
          subtitle: const Text(
            'Use the built-in backend emulator through the same manifest, sync, Drift and CURRENT repository pipeline.',
          ),
          value: mode == CatalogueSourceMode.demo,
          onChanged: _changing ? null : _setDemo,
        ),
        if (_changing) const LinearProgressIndicator(),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            'Unable to switch catalogue source: $_error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
