import 'dart:async';

import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../ports/audio_playback_engine.dart';
import '../ports/learner_state_repository.dart';
import '../result/result.dart';
import 'asset_resolver.dart';

typedef ResolveAudioAsset = Future<Result<ResolvedAsset>> Function(
  ContentIdentity content,
  int revision,
);

enum AudioPlaybackPhase {
  idle,
  resolving,
  playing,
  paused,
  stopped,
  completed,
  failed,
}

final class ContentPlaybackState {
  const ContentPlaybackState({
    this.phase = AudioPlaybackPhase.idle,
    this.content,
    this.revision,
    this.positionMs = 0,
    this.durationMs,
    this.failure,
  });

  final AudioPlaybackPhase phase;
  final ContentIdentity? content;
  final int? revision;
  final int positionMs;
  final int? durationMs;
  final ApplicationFailure? failure;

  bool isCurrent(ContentIdentity identity, int contentRevision) =>
      content == identity && revision == contentRevision;

  ContentPlaybackState copyWith({
    AudioPlaybackPhase? phase,
    ContentIdentity? content,
    int? revision,
    int? positionMs,
    int? durationMs,
    ApplicationFailure? failure,
    bool clearFailure = false,
    bool clearDuration = false,
  }) {
    return ContentPlaybackState(
      phase: phase ?? this.phase,
      content: content ?? this.content,
      revision: revision ?? this.revision,
      positionMs: positionMs ?? this.positionMs,
      durationMs: clearDuration ? null : durationMs ?? this.durationMs,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

final class AudioPlaybackController {
  factory AudioPlaybackController({
    required ResolveAudioAsset resolveAudioAsset,
    required AudioPlaybackEngine engine,
    required LearnerStateRepository learnerState,
    int progressSaveIntervalMs = 5000,
  }) {
    return AudioPlaybackController._(
      resolveAudioAsset,
      engine,
      learnerState,
      _requirePositiveInterval(progressSaveIntervalMs),
    );
  }

  AudioPlaybackController._(
    this._resolveAudioAsset,
    this._engine,
    this._learnerState,
    this._progressSaveIntervalMs,
  );

  final ResolveAudioAsset _resolveAudioAsset;
  final AudioPlaybackEngine _engine;
  final LearnerStateRepository _learnerState;
  final int _progressSaveIntervalMs;
  final StreamController<ContentPlaybackState> _states =
      StreamController<ContentPlaybackState>.broadcast();

  ContentPlaybackState _state = const ContentPlaybackState();
  AudioPlaybackSession? _session;
  StreamSubscription<AudioPlaybackEvent>? _eventSubscription;
  Future<void> _writeTail = Future<void>.value();
  int _generation = 0;
  int _lastSavedPositionMs = 0;
  bool _completionHandled = false;
  bool _disposed = false;

  ContentPlaybackState get state => _state;

  Stream<ContentPlaybackState> get states => _states.stream;

  Future<Result<void>> play(
    ContentItem item, {
    required ContentMarkerState learnerState,
  }) async {
    if (_disposed) return _closedFailure();
    final identity = ContentIdentity.fromItem(item);
    final restartFromBeginning =
        _state.isCurrent(identity, item.revision) &&
        _state.phase == AudioPlaybackPhase.completed;

    if (_state.isCurrent(identity, item.revision) && _session != null) {
      if (_state.phase == AudioPlaybackPhase.playing) {
        return const Success<void>(null);
      }
      if (_state.phase == AudioPlaybackPhase.paused) {
        return resume();
      }
    }

    final closeResult = await _closeCurrent(
      persistPosition: !restartFromBeginning,
    );
    if (closeResult case FailureResult<void>()) return closeResult;

    final generation = ++_generation;
    _completionHandled = false;
    _lastSavedPositionMs = 0;
    _emit(
      ContentPlaybackState(
        phase: AudioPlaybackPhase.resolving,
        content: identity,
        revision: item.revision,
      ),
    );

    final resolved = await _resolveAudioAsset(identity, item.revision);
    if (generation != _generation) return _supersededFailure();
    if (resolved case FailureResult<ResolvedAsset>(:final failure)) {
      return _fail(failure);
    }
    final asset = (resolved as Success<ResolvedAsset>).value;
    if (!asset.mediaType.toLowerCase().startsWith('audio/')) {
      return _fail(
        ApplicationFailure(
          code: 'ASSET_NOT_AUDIO',
          message: 'The resolved content asset is not playable audio.',
          details: <String, Object?>{'assetId': asset.assetId},
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
    _eventSubscription = session.events.listen(
      (event) => _handleEvent(event, generation),
    );
    final initialDuration = session.initialDuration?.inMilliseconds;
    if (initialDuration != null && initialDuration >= 0) {
      _emit(_state.copyWith(durationMs: initialDuration));
    }

    final resumePosition = restartFromBeginning
        ? 0
        : learnerState.lastRevisionSeen == item.revision
        ? learnerState.lastPositionMs ?? 0
        : 0;
    if (resumePosition > 0) {
      final seekResult = await session.seek(
        Duration(milliseconds: resumePosition),
      );
      if (seekResult case FailureResult<void>(:final failure)) {
        return _failAndClose(failure);
      }
      _lastSavedPositionMs = resumePosition;
    }

    final playResult = await session.play();
    if (playResult case FailureResult<void>(:final failure)) {
      return _failAndClose(failure);
    }

    _emit(
      _state.copyWith(
        phase: AudioPlaybackPhase.playing,
        positionMs: resumePosition,
        clearFailure: true,
      ),
    );
    return const Success<void>(null);
  }

  Future<Result<void>> pause() async {
    final session = _session;
    if (_disposed) return _closedFailure();
    if (session == null) return _noSessionFailure();

    final pauseResult = await session.pause();
    if (pauseResult case FailureResult<void>(:final failure)) {
      return _fail(failure);
    }
    final progressResult = await _persistCurrentPosition();
    if (progressResult case FailureResult<void>(:final failure)) {
      _emit(
        _state.copyWith(phase: AudioPlaybackPhase.paused, failure: failure),
      );
      return progressResult;
    }
    _emit(
      _state.copyWith(phase: AudioPlaybackPhase.paused, clearFailure: true),
    );
    return const Success<void>(null);
  }

  Future<Result<void>> resume() async {
    final session = _session;
    if (_disposed) return _closedFailure();
    if (session == null) return _noSessionFailure();

    final result = await session.play();
    if (result case FailureResult<void>(:final failure)) {
      return _fail(failure);
    }
    _emit(
      _state.copyWith(phase: AudioPlaybackPhase.playing, clearFailure: true),
    );
    return const Success<void>(null);
  }

  Future<Result<void>> seek(int positionMs) async {
    final session = _session;
    if (_disposed) return _closedFailure();
    if (session == null) return _noSessionFailure();

    final duration = _state.durationMs;
    final upperBound = duration ?? positionMs.clamp(0, 1 << 31).toInt();
    final clamped = positionMs.clamp(0, upperBound).toInt();
    final result = await session.seek(Duration(milliseconds: clamped));
    if (result case FailureResult<void>(:final failure)) {
      return _fail(failure);
    }
    _emit(_state.copyWith(positionMs: clamped, clearFailure: true));
    final progressResult = await _persistCurrentPosition();
    if (progressResult case FailureResult<void>(:final failure)) {
      _emit(_state.copyWith(failure: failure));
      return progressResult;
    }
    return const Success<void>(null);
  }

  Future<Result<void>> stop() async {
    if (_disposed) return _closedFailure();
    if (_session == null) return const Success<void>(null);

    final position = _state.positionMs;
    final content = _state.content;
    final revision = _state.revision;
    final session = _session!;
    final shouldPersist = _state.phase != AudioPlaybackPhase.completed;

    ++_generation;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _session = null;

    Result<void> progressResult = const Success<void>(null);
    if (shouldPersist && content != null && revision != null) {
      progressResult = await _persistPosition(content, revision, position);
    }
    final stopResult = await session.stop();
    await session.dispose();

    final failure = switch ((progressResult, stopResult)) {
      (FailureResult<void>(:final failure), _) => failure,
      (_, FailureResult<void>(:final failure)) => failure,
      _ => null,
    };
    _emit(
      _state.copyWith(
        phase: AudioPlaybackPhase.stopped,
        failure: failure,
        clearFailure: failure == null,
      ),
    );
    return failure == null
        ? const Success<void>(null)
        : FailureResult<void>(failure);
  }

  void _handleEvent(AudioPlaybackEvent event, int generation) {
    if (_disposed || generation != _generation) return;

    switch (event) {
      case AudioPositionChanged(:final position):
        final positionMs = position.inMilliseconds.clamp(0, 1 << 31).toInt();
        _emit(_state.copyWith(positionMs: positionMs));
        _scheduleProgressSave(positionMs, generation);
      case AudioDurationChanged(:final duration):
        _emit(
          _state.copyWith(
            durationMs: duration.inMilliseconds.clamp(0, 1 << 31).toInt(),
          ),
        );
      case AudioEngineStateChanged(:final state):
        if (state == AudioEngineState.playing) {
          _emit(_state.copyWith(phase: AudioPlaybackPhase.playing));
        } else if (state == AudioEngineState.paused) {
          _emit(_state.copyWith(phase: AudioPlaybackPhase.paused));
          _scheduleProgressSave(_state.positionMs, generation, force: true);
        }
      case AudioPlaybackCompleted():
        unawaited(_handleCompletion(generation));
    }
  }

  Future<void> _handleCompletion(int generation) async {
    if (_disposed || generation != _generation || _completionHandled) return;
    final content = _state.content;
    final revision = _state.revision;
    if (content == null || revision == null) return;

    _completionHandled = true;
    _emit(
      _state.copyWith(
        phase: AudioPlaybackPhase.completed,
        positionMs: _state.durationMs ?? _state.positionMs,
        clearFailure: true,
      ),
    );

    final listenedResult = await _learnerState.setListened(
      content,
      listened: true,
      lastRevisionSeen: revision,
    );
    final resetResult = await _persistPosition(content, revision, 0);
    _lastSavedPositionMs = 0;

    if (generation != _generation) return;
    final failure = switch ((listenedResult, resetResult)) {
      (FailureResult<void>(:final failure), _) => failure,
      (_, FailureResult<void>(:final failure)) => failure,
      _ => null,
    };
    if (failure != null) {
      _emit(_state.copyWith(failure: failure));
    }
  }

  void _scheduleProgressSave(
    int positionMs,
    int generation, {
    bool force = false,
  }) {
    final content = _state.content;
    final revision = _state.revision;
    if (content == null || revision == null || positionMs < 0) return;
    if (!force &&
        (positionMs - _lastSavedPositionMs).abs() < _progressSaveIntervalMs) {
      return;
    }

    _lastSavedPositionMs = positionMs;
    unawaited(
      _persistPosition(content, revision, positionMs).then((result) {
        if (_disposed || generation != _generation) return;
        if (result case FailureResult<void>(:final failure)) {
          _emit(_state.copyWith(failure: failure));
        }
      }),
    );
  }

  Future<Result<void>> _persistCurrentPosition() {
    final content = _state.content;
    final revision = _state.revision;
    if (content == null || revision == null) {
      return Future<Result<void>>.value(const Success<void>(null));
    }
    _lastSavedPositionMs = _state.positionMs;
    return _persistPosition(content, revision, _state.positionMs);
  }

  Future<Result<void>> _persistPosition(
    ContentIdentity content,
    int revision,
    int positionMs,
  ) async {
    final prior = _writeTail;
    late Result<void> outcome;
    final current = () async {
      try {
        await prior;
        outcome = await _learnerState.savePlaybackPosition(
          content,
          positionMs: positionMs,
          lastRevisionSeen: revision,
        );
      } catch (error) {
        outcome = FailureResult<void>(
          ApplicationFailure(
            code: 'PLAYBACK_PROGRESS_WRITE_FAILED',
            message: 'Playback progress could not be persisted.',
            retryable: true,
            details: <String, Object?>{
              'errorType': error.runtimeType.toString(),
            },
          ),
        );
      }
    }();
    _writeTail = current;
    await current;
    return outcome;
  }

  Future<Result<void>> _closeCurrent({required bool persistPosition}) async {
    final session = _session;
    final content = _state.content;
    final revision = _state.revision;
    final position = _state.positionMs;
    final shouldPersist =
        persistPosition && _state.phase != AudioPlaybackPhase.completed;

    ++_generation;
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _session = null;

    Result<void> progressResult = const Success<void>(null);
    if (shouldPersist &&
        session != null &&
        content != null &&
        revision != null) {
      progressResult = await _persistPosition(content, revision, position);
    }

    Result<void> stopResult = const Success<void>(null);
    if (session != null) {
      stopResult = await session.stop();
      await session.dispose();
    }

    if (progressResult case FailureResult<void>()) return progressResult;
    return stopResult;
  }

  Result<void> _fail(ApplicationFailure failure) {
    _emit(_state.copyWith(phase: AudioPlaybackPhase.failed, failure: failure));
    return FailureResult<void>(failure);
  }

  Future<Result<void>> _failAndClose(ApplicationFailure failure) async {
    await _closeCurrent(persistPosition: false);
    return _fail(failure);
  }

  void _emit(ContentPlaybackState next) {
    _state = next;
    if (!_disposed && !_states.isClosed) {
      _states.add(next);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await _closeCurrent(persistPosition: true);
    _disposed = true;
    await _writeTail;
    await _states.close();
  }

  static FailureResult<void> _closedFailure() => const FailureResult<void>(
    ApplicationFailure(
      code: 'AUDIO_CONTROLLER_CLOSED',
      message: 'The audio playback controller is already closed.',
    ),
  );

  static FailureResult<void> _noSessionFailure() => const FailureResult<void>(
    ApplicationFailure(
      code: 'AUDIO_SESSION_UNAVAILABLE',
      message: 'No audio playback session is active.',
    ),
  );

  static FailureResult<void> _supersededFailure() => const FailureResult<void>(
    ApplicationFailure(
      code: 'PLAYBACK_SUPERSEDED',
      message: 'A newer playback request replaced this request.',
      retryable: true,
    ),
  );

  static int _requirePositiveInterval(int value) {
    if (value < 1) {
      throw ArgumentError.value(
        value,
        'progressSaveIntervalMs',
        'must be positive',
      );
    }
    return value;
  }
}
