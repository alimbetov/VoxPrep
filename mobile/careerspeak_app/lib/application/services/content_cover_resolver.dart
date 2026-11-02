import '../../domain/content_identity.dart';
import '../content_delivery/content_visual_policy.dart';
import '../result/result.dart';
import 'asset_resolver.dart';

/// Resolves the optional preview-safe cover for one exact content revision.
///
/// Cover availability is deliberately fail-soft for learner presentation. Missing
/// metadata, missing local bytes, delivery failures and unsupported visual media
/// all mean "no cover"; they must not make otherwise valid learning content
/// unavailable.
final class ContentCoverResolver {
  const ContentCoverResolver(this._assets);

  final AssetResolver _assets;

  Future<ResolvedAsset?> resolve({
    required ContentIdentity content,
    required int revision,
    AssetResolutionPolicy policy = AssetResolutionPolicy.downloadIfMissing,
  }) async {
    final result = await _assets.resolveImageContent(
      content: content,
      revision: revision,
      role: ContentVisualRole.coverImage.wireName,
      policy: policy,
    );

    return switch (result) {
      Success<ResolvedAsset>(:final value) =>
        ContentVisualPolicy.isSupportedCoverMediaType(value.mediaType)
            ? value
            : null,
      FailureResult<ResolvedAsset>() => null,
    };
  }
}
