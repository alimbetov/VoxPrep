import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/billing_providers.dart';
import '../../app/purchase_providers.dart';
import '../../application/access/store_product.dart';
import '../../application/result/result.dart';
import '../../application/services/full_unlock_purchase_coordinator.dart';

const fullUnlockLocation = '/unlock';

class FullUnlockScreen extends ConsumerWidget {
  const FullUnlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(fullUnlockStoreProductProvider);
    final purchaseState = ref.watch(fullUnlockPurchaseStateProvider);
    final busy = purchaseState.when(
      data: (value) => value.busy,
      loading: () => false,
      error: (error, stackTrace) => false,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: Text(
                        'VOXPREP FULL',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Unlock every learning path',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'One payment unlocks the complete VoxPrep catalogue, practice tests, audio and entitled offline content.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _Benefit(text: 'All learning collections'),
                        _Benefit(text: 'Included practice tests'),
                        _Benefit(text: 'Included audio'),
                        _Benefit(text: 'Offline access for entitled content'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    Chip(label: Text('No subscription')),
                    Chip(label: Text('One-time unlock')),
                    Chip(label: Text('Restore purchases anytime')),
                  ],
                ),
                const SizedBox(height: 24),
                product.when(
                  data: (value) => _StoreProductPanel(
                    product: value,
                    busy: busy,
                    onPurchase: () => _purchase(context, ref, value),
                  ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => const _StoreUnavailablePanel(),
                ),
                const SizedBox(height: 12),
                purchaseState.when(
                  data: (value) => _PurchaseStatusPanel(state: value),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const _PurchaseStatusPanel(
                    state: FullUnlockPurchaseState(
                      phase: FullUnlockPurchasePhase.failed,
                      message: 'Purchase status is temporarily unavailable.',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('full-unlock-restore-button'),
                  onPressed: busy ? null : () => _restore(context, ref),
                  child: const Text('Restore Purchases'),
                ),
                Text(
                  'Purchases are processed by your app store. VoxPrep unlocks Full access only after the purchase is verified.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    StoreProduct product,
  ) async {
    final result = await ref
        .read(fullUnlockPurchaseCoordinatorProvider)
        .purchase(product);
    if (!context.mounted) return;
    _showImmediateFailure(context, result);
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(fullUnlockPurchaseCoordinatorProvider)
        .restore();
    if (!context.mounted) return;
    _showImmediateFailure(context, result);
  }

  void _showImmediateFailure(BuildContext context, Result<void> result) {
    if (result case FailureResult<void>(:final failure)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }
}

class _StoreProductPanel extends StatelessWidget {
  const _StoreProductPanel({
    required this.product,
    required this.busy,
    required this.onPurchase,
  });

  final StoreProduct product;
  final bool busy;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(
              product.localizedPrice,
              key: const Key('full-unlock-localized-price'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text('One-time purchase'),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('full-unlock-purchase-button'),
                onPressed: busy ? null : onPurchase,
                child: Text(busy ? 'Please wait…' : 'Unlock Full VoxPrep'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseStatusPanel extends StatelessWidget {
  const _PurchaseStatusPanel({required this.state});

  final FullUnlockPurchaseState state;

  @override
  Widget build(BuildContext context) {
    if (state.phase == FullUnlockPurchasePhase.idle || state.message.isEmpty) {
      return const SizedBox.shrink();
    }

    final icon = switch (state.phase) {
      FullUnlockPurchasePhase.unlocked => Icons.verified_outlined,
      FullUnlockPurchasePhase.failed => Icons.error_outline,
      FullUnlockPurchasePhase.cancelled => Icons.info_outline,
      _ => null,
    };

    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            key: const Key('full-unlock-purchase-status'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.busy) ...[
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(child: Text(state.message, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreUnavailablePanel extends StatelessWidget {
  const _StoreUnavailablePanel();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, size: 32),
            SizedBox(height: 10),
            Text(
              'Store purchases are temporarily unavailable.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'You can keep using the free content and try again later.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 21,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
