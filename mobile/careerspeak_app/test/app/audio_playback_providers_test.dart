import 'package:careerspeak_app/app/asset_resolver_providers.dart';
import 'package:careerspeak_app/app/audio_playback_providers.dart';
import 'package:careerspeak_app/application/content_delivery/content_audio_policy.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test(
    'INTERVIEW exposes only roles present in CURRENT exact revision',
    () async {
      final container = ProviderContainer(
        overrides: [
          assetCatalogRepositoryProvider.overrideWithValue(
            _RoleCatalog(<String>{ContentAudioRole.question.wireName}),
          ),
        ],
      );
      addTearDown(container.dispose);

      final roles = await container.read(
        interviewAudioAvailableRolesProvider((
          content: const ContentIdentity(
            code: 'JAVA_INTERVIEW_1',
            type: ContentType.interview,
          ),
          revision: 3,
        )).future,
      );

      expect(roles, <ContentAudioRole>{ContentAudioRole.question});
      expect(roles, isNot(contains(ContentAudioRole.sampleAnswer)));
    },
  );
}

final class _RoleCatalog implements AssetCatalogRepository {
  const _RoleCatalog(this.roles);

  final Set<String> roles;

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(
    String assetId,
  ) async {
    return const Success<ManifestAssetDescriptor?>(null);
  }

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async {
    if (!roles.contains(role)) {
      return const Success<ManifestAssetDescriptor?>(null);
    }
    return Success<ManifestAssetDescriptor?>(
      ManifestAssetDescriptor(
        assetId: 'asset-$role',
        checksumSha256: _hash,
        deliveryKey: 'audio/asset-$role.mp3',
        sizeBytes: 4,
        mediaType: 'audio/mpeg',
        requiredOffline: false,
      ),
    );
  }
}
