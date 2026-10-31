import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/asset_resolver_providers.dart';

class CatalogueAssetIcon extends ConsumerWidget {
  const CatalogueAssetIcon({required this.assetId, this.size = 32, super.key});

  final String assetId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(catalogueIconAssetProvider(assetId));
    return SizedBox.square(
      dimension: size,
      child: resolved.when(
        loading: () => const Center(
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const Icon(Icons.school_outlined),
        data: (asset) => asset == null
            ? const Icon(Icons.school_outlined)
            : Image.file(
                File(asset.localPath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.school_outlined),
              ),
      ),
    );
  }
}
