import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/billing_providers.dart';
import '../../application/access/store_product.dart';
import '../../application/result/result.dart';

class FullUnlockScreen extends ConsumerStatefulWidget {
  const FullUnlockScreen({super.key});

  @override
  ConsumerState<FullUnlockScreen> createState() => _FullUnlockScreenState();
}

class _FullUnlockScreenState extends ConsumerState<FullUnlockScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(fullUnlockStoreProductProvider);
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
            busy: _busy,
            onPurchase: () => _purchase(value),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _StoreUnavailablePanel(),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _busy ? null : _restore,
          child: const Text('Restore Purchases'),
        ),
      ],
    );
  }

  Future<void> _purchase(StoreProduct product) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(billingRepositoryProvider)
          .purchaseFullUnlock(product);
      if (!mounted) return;
      _showResult(result, successMessage: 'Purchase started.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(billingRepositoryProvider)
          .restorePurchases();
      if (!mounted) return;
      _showResult(result, successMessage: 'Restore started.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showResult(Result<void> result, {required String successMessage}) {
    final message = switch (result) {
      Success<void>() => successMessage,
      FailureResult<void>(:final failure) => failure.message,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
