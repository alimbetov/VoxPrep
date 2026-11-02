import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/asset_resolver_providers.dart';
import '../../domain/content_identity.dart';

typedef ContentCoverImageBuilder =
    Widget Function({
      required BuildContext context,
      required String localPath,
      required double? width,
      required double? height,
      required BoxFit fit,
      required BorderRadius borderRadius,
      required String? semanticLabel,
    });

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
    @visibleForTesting this.imageBuilder,
    super.key,
  });

  final ContentIdentity content;
  final int revision;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  /// Test seam for deterministic layout qualification without depending on the
  /// native headless image codec. Production always uses [FileImage] over an
  /// already checksum-verified asset path.
  @visibleForTesting
  final ContentCoverImageBuilder? imageBuilder;

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

        final testBuilder = imageBuilder;
        if (testBuilder != null) {
          return testBuilder(
            context: context,
            localPath: asset.localPath,
            width: width,
            height: height,
            fit: fit,
            borderRadius: borderRadius,
            semanticLabel: semanticLabel,
          );
        }

        return Image(
          image: FileImage(File(asset.localPath)),
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
