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
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.lock_open_outlined, size: 52),
        const SizedBox(height: 20),
        Text(
          'Unlock Full VoxPrep',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Get access to the complete VoxPrep catalogue.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const _Benefit(text: 'All learning collections'),
        const _Benefit(text: 'Included practice tests'),
        const _Benefit(text: 'Included audio'),
        const _Benefit(text: 'Offline access for entitled content'),
        const SizedBox(height: 28),
        product.when(
          data: (value) => _StoreProductPanel(
            product: value,
            busy: busy,
            onPurchase: () => _purchase(context, ref, value),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
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
    return Column(
      children: [
        Text(
          product.localizedPrice,
          key: const Key('full-unlock-localized-price'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text('One-time purchase'),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('full-unlock-purchase-button'),
            onPressed: busy ? null : onPurchase,
            child: const Text('Unlock Full VoxPrep'),
          ),
        ),
      ],
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
    );
  }
}

class _StoreUnavailablePanel extends StatelessWidget {
  const _StoreUnavailablePanel();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Store purchases are temporarily unavailable.',
          textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
