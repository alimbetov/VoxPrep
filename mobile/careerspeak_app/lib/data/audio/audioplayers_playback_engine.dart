import 'dart:async';

import 'package:audioplayers/audioplayers.dart' as audio;

import '../../application/ports/audio_playback_engine.dart';
import '../../application/result/result.dart';

final class AudioplayersPlaybackEngine implements AudioPlaybackEngine {
  const AudioplayersPlaybackEngine();

  @override
  Future<Result<AudioPlaybackSession>> openLocal({
    required String path,
    required String mediaType,
  }) async {
    final player = audio.AudioPlayer();
    final session = _AudioplayersPlaybackSession(player);
    try {
      await player.setReleaseMode(audio.ReleaseMode.stop);
      await player.setSource(audio.DeviceFileSource(path, mimeType: mediaType));
      try {
        session.initialDuration = await player.getDuration();
      } on Object {
        // Duration is optional; the native stream may provide it after play.
      }
      return Success<AudioPlaybackSession>(session);
    } catch (error) {
      await session.dispose();
      return FailureResult<AudioPlaybackSession>(
        ApplicationFailure(
          code: 'AUDIO_SOURCE_OPEN_FAILED',
          message: 'The verified local audio file could not be opened.',
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }
}

final class _AudioplayersPlaybackSession implements AudioPlaybackSession {
  _AudioplayersPlaybackSession(this._player) {
    _subscriptions.addAll(<StreamSubscription<Object?>>[
      _player.onPositionChanged.listen(
        (position) => _emit(AudioPositionChanged(position)),
      ),
      _player.onDurationChanged.listen(
        (duration) => _emit(AudioDurationChanged(duration)),
      ),
      _player.onPlayerComplete.listen(
        (_) => _emit(const AudioPlaybackCompleted()),
      ),
      _player.onPlayerStateChanged.listen((state) {
        final mapped = switch (state) {
          audio.PlayerState.playing => AudioEngineState.playing,
          audio.PlayerState.paused => AudioEngineState.paused,
          audio.PlayerState.stopped => AudioEngineState.stopped,
          audio.PlayerState.completed => null,
          audio.PlayerState.disposed => null,
        };
        if (mapped != null) {
          _emit(AudioEngineStateChanged(mapped));
        }
      }),
    ]);
  }

  final audio.AudioPlayer _player;
  final StreamController<AudioPlaybackEvent> _events =
      StreamController<AudioPlaybackEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  bool _disposed = false;

  @override
  Duration? initialDuration;

  @override
  Stream<AudioPlaybackEvent> get events => _events.stream;

  @override
  Future<Result<void>> play() => _run(
    code: 'AUDIO_PLAY_FAILED',
    message: 'Audio playback could not be started.',
    action: _player.resume,
  );

  @override
  Future<Result<void>> pause() => _run(
    code: 'AUDIO_PAUSE_FAILED',
    message: 'Audio playback could not be paused.',
    action: _player.pause,
  );

  @override
  Future<Result<void>> seek(Duration position) => _run(
    code: 'AUDIO_SEEK_FAILED',
    message: 'Audio playback position could not be changed.',
    action: () => _player.seek(position),
  );

  @override
  Future<Result<void>> stop() => _run(
    code: 'AUDIO_STOP_FAILED',
    message: 'Audio playback could not be stopped.',
    action: _player.stop,
  );

  Future<Result<void>> _run({
    required String code,
    required String message,
    required Future<void> Function() action,
  }) async {
    if (_disposed) {
      return const FailureResult<void>(
        ApplicationFailure(
          code: 'AUDIO_SESSION_CLOSED',
          message: 'The audio playback session is already closed.',
        ),
      );
    }
    try {
      await action();
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: code,
          message: message,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  void _emit(AudioPlaybackEvent event) {
    if (!_disposed && !_events.isClosed) {
      _events.add(event);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    try {
      await _player.dispose();
    } finally {
      await _events.close();
    }
  }
}
