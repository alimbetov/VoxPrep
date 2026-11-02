import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/asset_resolver_providers.dart';
import '../../domain/content_identity.dart';

typedef ContentCoverImageProviderFactory =
    ImageProvider<Object> Function(String localPath);

/// Optional exact-revision content cover.
///
/// The widget intentionally reserves no space while the cover is unavailable,
/// loading, missing or undecodable. A cover is presentation enrichment; learner
/// content remains fully usable without it.
class ContentCover extends ConsumerWidget {
  const ContentCover({
    required this.content,
    required this.revision,
    this.width = double.infinity,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.semanticLabel,
    @visibleForTesting this.imageProviderFactory,
    super.key,
  });

  final ContentIdentity content;
  final int revision;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  /// Test seam for deterministic image-decoder failure qualification.
  /// Production always uses [FileImage] over an already verified asset path.
  @visibleForTesting
  final ContentCoverImageProviderFactory? imageProviderFactory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(
      contentCoverAssetProvider((content: content, revision: revision)),
    );

    return resolved.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (asset) {
        if (asset == null) return const SizedBox.shrink();

        final imageProvider =
            imageProviderFactory?.call(asset.localPath) ??
            FileImage(File(asset.localPath));
        return Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (!wasSynchronouslyLoaded && frame == null) {
              return const SizedBox.shrink();
            }
            if (borderRadius == BorderRadius.zero) return child;
            return ClipRRect(borderRadius: borderRadius, child: child);
          },
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      },
    );
  }
}
