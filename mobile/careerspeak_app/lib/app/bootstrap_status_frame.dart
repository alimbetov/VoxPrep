import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/result/result.dart';
import 'application_bootstrap_providers.dart';

/// Keeps the local-first application usable while surfacing a safe bootstrap
/// failure. The banner never exposes transport/backend exception text.
class BootstrapStatusFrame extends ConsumerWidget {
  const BootstrapStatusFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(applicationBootstrapProvider);
    final failed = bootstrap.asData?.value is FailureResult;

    if (!failed) return child;

    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Could not refresh data. Saved content remains available.',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(applicationBootstrapProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
