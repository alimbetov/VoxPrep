import 'package:careerspeak_app/app/asset_resolver_providers.dart';
import 'package:careerspeak_app/app/audio_playback_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/role_audio_clip_controller.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/content/content_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  testWidgets(
    'published INTERVIEW role remains visible when legacy hasAudio is false',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learnerStateRepositoryProvider.overrideWithValue(
              const _EmptyLearnerStateRepository(),
            ),
            assetCatalogRepositoryProvider.overrideWithValue(
              const _QuestionRoleCatalog(),
            ),
            interviewAudioClipStateProvider.overrideWith(
              (ref) => Stream<RoleAudioClipState>.value(
                const RoleAudioClipState(),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ContentDetailPanel(item: _interview)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Question'), findsOneWidget);
      expect(find.text('Sample answer'), findsNothing);
    },
  );
}

const _interview = ContentItem(
  code: 'INTERVIEW_LEGACY_FLAG_FALSE',
  type: ContentType.interview,
  title: 'Interview',
  subtitle: 'Question role is authoritative',
  description: 'Role bindings come from CURRENT publication membership.',
  category: 'JAVA',
  level: 'B2',
  minutes: 3,
  revision: 7,
  hasAudio: false,
);

final class _EmptyLearnerStateRepository implements LearnerStateRepository {
  const _EmptyLearnerStateRepository();

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() =>
      Stream<Result<Map<ContentIdentity, ContentMarkerState>>>.value(
        const Success<Map<ContentIdentity, ContentMarkerState>>(
          <ContentIdentity, ContentMarkerState>{},
        ),
      );

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);
}

final class _QuestionRoleCatalog implements AssetCatalogRepository {
  const _QuestionRoleCatalog();

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(
    String assetId,
  ) async => const Success<ManifestAssetDescriptor?>(null);

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async {
    if (role != 'question') {
      return const Success<ManifestAssetDescriptor?>(null);
    }
    return Success<ManifestAssetDescriptor?>(
      ManifestAssetDescriptor(
        assetId: 'asset-question',
        checksumSha256: _hash,
        deliveryKey: 'audio/question.mp3',
        sizeBytes: 4,
        mediaType: 'audio/mpeg',
        requiredOffline: false,
      ),
    );
  }
}
