import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/audio_playback_engine.dart';
import '../application/services/asset_resolver.dart';
import '../application/services/audio_playback_controller.dart';
import '../data/audio/audioplayers_playback_engine.dart';
import 'asset_resolver_providers.dart';
import 'learner_state_providers.dart';

final audioPlaybackEngineProvider = Provider<AudioPlaybackEngine>((ref) {
  return const AudioplayersPlaybackEngine();
});

final audioPlaybackControllerProvider = Provider<AudioPlaybackController>((
  ref,
) {
  final controller = AudioPlaybackController(
    resolveAudioAsset: (content, revision) async {
      final resolver = await ref.read(assetResolverProvider.future);
      return resolver.resolveContent(
        content: content,
        revision: revision,
        role: 'promptAudio',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
    },
    engine: ref.watch(audioPlaybackEngineProvider),
    learnerState: ref.watch(learnerStateRepositoryProvider),
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
