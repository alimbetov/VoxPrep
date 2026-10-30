import '../result/result.dart';

enum AudioEngineState { playing, paused, stopped }

sealed class AudioPlaybackEvent {
  const AudioPlaybackEvent();
}

final class AudioPositionChanged extends AudioPlaybackEvent {
  const AudioPositionChanged(this.position);

  final Duration position;
}

final class AudioDurationChanged extends AudioPlaybackEvent {
  const AudioDurationChanged(this.duration);

  final Duration duration;
}

final class AudioEngineStateChanged extends AudioPlaybackEvent {
  const AudioEngineStateChanged(this.state);

  final AudioEngineState state;
}

final class AudioPlaybackCompleted extends AudioPlaybackEvent {
  const AudioPlaybackCompleted();
}

abstract interface class AudioPlaybackSession {
  Duration? get initialDuration;

  Stream<AudioPlaybackEvent> get events;

  Future<Result<void>> play();

  Future<Result<void>> pause();

  Future<Result<void>> seek(Duration position);

  Future<Result<void>> stop();

  Future<void> dispose();
}

abstract interface class AudioPlaybackEngine {
  Future<Result<AudioPlaybackSession>> openLocal({
    required String path,
    required String mediaType,
  });
}
