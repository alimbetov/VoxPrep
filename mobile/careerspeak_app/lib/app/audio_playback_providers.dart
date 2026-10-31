import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_delivery/content_audio_policy.dart';
import '../application/result/result.dart';
import '../application/ports/audio_playback_engine.dart';
import '../application/services/asset_resolver.dart';
import '../application/services/audio_playback_controller.dart';
import '../application/services/role_audio_clip_controller.dart';
import '../data/audio/audioplayers_playback_engine.dart';
import '../domain/content_identity.dart';
import 'asset_resolver_providers.dart';
import 'learner_state_providers.dart';

typedef InterviewAudioRoleQuery = ({ContentIdentity content, int revision});

final audioPlaybackEngineProvider = Provider<AudioPlaybackEngine>((ref) {
  return const AudioplayersPlaybackEngine();
});

final interviewAudioAvailableRolesProvider =
    FutureProvider.family<Set<ContentAudioRole>, InterviewAudioRoleQuery>((
      ref,
      query,
    ) async {
      final catalog = ref.watch(assetCatalogRepositoryProvider);
      final available = <ContentAudioRole>{};
      for (final role in const <ContentAudioRole>[
        ContentAudioRole.question,
        ContentAudioRole.sampleAnswer,
      ]) {
        final result = await catalog.findCurrentForContent(
          content: query.content,
          revision: query.revision,
          role: role.wireName,
        );
        switch (result) {
          case Success(:final value):
            if (value != null) available.add(role);
          case FailureResult(:final failure):
            throw StateError(
              'Unable to resolve published interview audio role '
              '${role.wireName}: ${failure.code}',
            );
        }
      }
      return Set<ContentAudioRole>.unmodifiable(available);
    });

final audioPlaybackControllerProvider = Provider<AudioPlaybackController>((
  ref,
) {
  final controller = AudioPlaybackController(
    resolveAudioAsset: (content, revision) async {
      final resolver = await ref.read(assetResolverProvider.future);
      final role = ContentAudioPolicy.primaryRole(content.type);
      return resolver.resolveContent(
        content: content,
        revision: revision,
        role: role.wireName,
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
    },
    engine: ref.watch(audioPlaybackEngineProvider),
    learnerState: ref.watch(learnerStateRepositoryProvider),
  );
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

final interviewAudioClipControllerProvider = Provider<RoleAudioClipController>((
  ref,
) {
  final controller = RoleAudioClipController(
    resolveAudioAsset: (content, revision, role) async {
      final resolver = await ref.read(assetResolverProvider.future);
      return resolver.resolveContent(
        content: content,
        revision: revision,
        role: role.wireName,
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
    },
    engine: ref.watch(audioPlaybackEngineProvider),
  );
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

final audioPlaybackStateProvider = StreamProvider<ContentPlaybackState>((
  ref,
) async* {
  final controller = ref.watch(audioPlaybackControllerProvider);
  yield controller.state;
  yield* controller.states;
});

final interviewAudioClipStateProvider = StreamProvider<RoleAudioClipState>((
  ref,
) async* {
  final controller = ref.watch(interviewAudioClipControllerProvider);
  yield controller.state;
  yield* controller.states;
});
