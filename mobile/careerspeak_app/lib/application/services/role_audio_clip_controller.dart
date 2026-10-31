import 'dart:async';

import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../content_delivery/content_audio_policy.dart';
import '../ports/audio_playback_engine.dart';
import '../result/result.dart';
import 'asset_resolver.dart';

typedef ResolveRoleAudioAsset =
    Future<Result<ResolvedAsset>> Function(
      ContentIdentity content,
      int revision,
      ContentAudioRole role,
    );

final class RoleAudioClipState {
  const RoleAudioClipState({
    this.phase = AudioPlaybackPhase.idle,
    this.role,
    this.positionMs = 0,
    this.durationMs,
    this.failure,
  });

  final AudioPlaybackPhase phase;
  final ContentAudioRole? role;
  final int positionMs;
  final int? durationMs;
  final ApplicationFailure? failure;
}

enum AudioPlaybackPhase {
  idle,
  resolving,
  playing,
  paused,
  stopped,
  completed,
  failed,
}

/// Single-session role-aware clip player for content that owns more than one
/// independent audio asset, notably INTERVIEW question/sample-answer audio.
///
/// It intentionally does not persist playback position: the current learner
/// state schema stores one position per ContentRevision and must not conflate
/// two independent role streams.
final class RoleAudioClipController {
  RoleAudioClipController({
    required ResolveRoleAudioAsset resolveAudioAsset,
    required AudioPlaybackEngine engine,
  }) : _resolveAudioAsset = resolveAudioAsset,
       _engine = engine;

  final ResolveRoleAudioAsset _resolveAudioAsset;
  final AudioPlaybackEngine _engine;
  final StreamController<RoleAudioClipState> _states =
      StreamController<RoleAudioClipState>.broadcast();

  RoleAudioClipState _state = const RoleAudioClipState();
  AudioPlaybackSession? _session;
  StreamSubscription<AudioPlaybackEvent>? _events;
  int _generation = 0;
  bool _disposed = false;

  RoleAudioClipState get state => _state;
  Stream<RoleAudioClipState> get states => _states.stream;

  Future<Result<void>> play(ContentItem item, ContentAudioRole role) async {
    if (_disposed) return _closedFailure();
    if (!ContentAudioPolicy.allows(item.type, role)) {
      return _fail(
        ApplicationFailure(
          code: 'AUDIO_ROLE_NOT_ALLOWED',
          message:
              'The requested audio role is not valid for this content type.',
          details: <String, Object?>{
            'contentType': item.type.name,
            'role': role.wireName,
          },
        ),
      );
    }

    if (_state.role == role && _session != null) {
      if (_state.phase == AudioPlaybackPhase.playing) {
        return const Success<void>(null);
      }
      if (_state.phase == AudioPlaybackPhase.paused) {
        return resume();
      }
    }

    await _closeCurrent();
    final generation = ++_generation;
    _emit(RoleAudioClipState(phase: AudioPlaybackPhase.resolving, role: role));

    final identity = ContentIdentity.fromItem(item);
    final resolved = await _resolveAudioAsset(identity, item.revision, role);
    if (generation != _generation) return _supersededFailure();
    if (resolved case FailureResult<ResolvedAsset>(:final failure)) {
      return _fail(failure);
    }

    final asset = (resolved as Success<ResolvedAsset>).value;
    if (!asset.mediaType.toLowerCase().startsWith('audio/')) {
      return _fail(
        ApplicationFailure(
          code: 'ASSET_NOT_AUDIO',
          message: 'The resolved role asset is not playable audio.',
          details: <String, Object?>{
            'assetId': asset.assetId,
            'role': role.wireName,
          },
        ),
      );
    }

    final opened = await _engine.openLocal(
      path: asset.localPath,
      mediaType: asset.mediaType,
    );
    if (generation != _generation) {
      if (opened case Success<AudioPlaybackSession>(:final value)) {
        await value.dispose();
      }
      return _supersededFailure();
    }
    if (opened case FailureResult<AudioPlaybackSession>(:final failure)) {
      return _fail(failure);
    }

    final session = (opened as Success<AudioPlaybackSession>).value;
    _session = session;
    _events = session.events.listen((event) => _handleEvent(event, generation));
    final duration = session.initialDuration?.inMilliseconds;
    if (duration != null && duration >= 0) {
      _emit(
        RoleAudioClipState(
          phase: AudioPlaybackPhase.resolving,
          role: role,
          durationMs: duration,
        ),
      );
    }

    final played = await session.play();
    if (played case FailureResult<void>(:final failure)) {
      await _closeCurrent();
      return _fail(failure);
    }

    _emit(
      RoleAudioClipState(
        phase: AudioPlaybackPhase.playing,
        role: role,
        durationMs: duration,
      ),
    );
    return const Success<void>(null);
  }

  Future<Result<void>> pause() async {
    final session = _session;
    if (_disposed) return _closedFailure();
    if (session == null) return _noSessionFailure();
    final result = await session.pause();
    if (result case FailureResult<void>(:final failure)) return _fail(failure);
    _emit(
      RoleAudioClipState(
        phase: AudioPlaybackPhase.paused,
        role: _state.role,
        positionMs: _state.positionMs,
        durationMs: _state.durationMs,
      ),
    );
    return const Success<void>(null);
  }

  Future<Result<void>> resume() async {
    final session = _session;
    if (_disposed) return _closedFailure();
    if (session == null) return _noSessionFailure();
    final result = await session.play();
    if (result case FailureResult<void>(:final failure)) return _fail(failure);
    _emit(
      RoleAudioClipState(
        phase: AudioPlaybackPhase.playing,
        role: _state.role,
        positionMs: _state.positionMs,
        durationMs: _state.durationMs,
      ),
    );
    return const Success<void>(null);
  }

  Future<Result<void>> stop() async {
    if (_disposed) return _closedFailure();
    if (_session == null) {
      if (_state.phase == AudioPlaybackPhase.resolving) {
        ++_generation;
        _emit(
          RoleAudioClipState(
            phase: AudioPlaybackPhase.stopped,
            role: _state.role,
            positionMs: _state.positionMs,
            durationMs: _state.durationMs,
          ),
        );
      }
      return const Success<void>(null);
    }
    final result = await _closeCurrent();
    _emit(
      RoleAudioClipState(
        phase: AudioPlaybackPhase.stopped,
        role: _state.role,
        positionMs: _state.positionMs,
        durationMs: _state.durationMs,
      ),
    );
    return result;
  }

  void _handleEvent(AudioPlaybackEvent event, int generation) {
    if (_disposed || generation != _generation) return;
    switch (event) {
      case AudioPositionChanged(:final position):
        _emit(
          RoleAudioClipState(
            phase: _state.phase,
            role: _state.role,
            positionMs: position.inMilliseconds.clamp(0, 1 << 31).toInt(),
            durationMs: _state.durationMs,
            failure: _state.failure,
          ),
        );
      case AudioDurationChanged(:final duration):
        _emit(
          RoleAudioClipState(
            phase: _state.phase,
            role: _state.role,
            positionMs: _state.positionMs,
            durationMs: duration.inMilliseconds.clamp(0, 1 << 31).toInt(),
            failure: _state.failure,
          ),
        );
      case AudioEngineStateChanged(:final state):
        final phase = switch (state) {
          AudioEngineState.playing => AudioPlaybackPhase.playing,
          AudioEngineState.paused => AudioPlaybackPhase.paused,
          _ => _state.phase,
        };
        _emit(
          RoleAudioClipState(
            phase: phase,
            role: _state.role,
            positionMs: _state.positionMs,
            durationMs: _state.durationMs,
          ),
        );
      case AudioPlaybackCompleted():
        _emit(
          RoleAudioClipState(
            phase: AudioPlaybackPhase.completed,
            role: _state.role,
            positionMs: _state.durationMs ?? _state.positionMs,
            durationMs: _state.durationMs,
          ),
        );
    }
  }

  Future<Result<void>> _closeCurrent() async {
    ++_generation;
    await _events?.cancel();
    _events = null;
    final session = _session;
    _session = null;
    if (session == null) return const Success<void>(null);
    final stopped = await session.stop();
    await session.dispose();
    return stopped;
  }

  Result<void> _fail(ApplicationFailure failure) {
    _emit(
      RoleAudioClipState(
        phase: AudioPlaybackPhase.failed,
        role: _state.role,
        positionMs: _state.positionMs,
        durationMs: _state.durationMs,
        failure: failure,
      ),
    );
    return FailureResult<void>(failure);
  }

  void _emit(RoleAudioClipState next) {
    _state = next;
    if (!_disposed && !_states.isClosed) _states.add(next);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await _closeCurrent();
    _disposed = true;
    await _states.close();
  }

  static FailureResult<void> _closedFailure() => const FailureResult<void>(
    ApplicationFailure(
      code: 'ROLE_AUDIO_CONTROLLER_CLOSED',
      message: 'The role-aware audio controller is closed.',
    ),
  );

  static FailureResult<void> _noSessionFailure() => const FailureResult<void>(
    ApplicationFailure(
      code: 'ROLE_AUDIO_SESSION_MISSING',
      message: 'No role-aware audio session is active.',
    ),
  );

  static FailureResult<void> _supersededFailure() => const FailureResult<void>(
    ApplicationFailure(
      code: 'ROLE_AUDIO_REQUEST_SUPERSEDED',
      message: 'A newer role-aware audio request superseded this request.',
      retryable: true,
    ),
  );
}
