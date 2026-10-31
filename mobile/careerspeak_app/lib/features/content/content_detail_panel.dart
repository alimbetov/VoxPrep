import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/audio_playback_providers.dart';
import '../../app/learner_state_providers.dart';
import '../../application/content_delivery/content_audio_policy.dart';
import '../../application/services/audio_playback_controller.dart';
import '../../application/services/role_audio_clip_controller.dart'
    as role_audio;
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import '../shared/content_marker_chips.dart';

class ContentDetailPanel extends ConsumerWidget {
  const ContentDetailPanel({required this.item, super.key});

  final ContentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ContentIdentity.fromItem(item);
    final markers = ref.watch(contentMarkersProvider);

    return markers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load learner state.\n$error'),
        ),
      ),
      data: (values) {
        final marker = values[identity] ?? const ContentMarkerState();
        return _buildContent(context, ref, identity, marker);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ContentIdentity identity,
    ContentMarkerState marker,
  ) {
    final repository = ref.read(learnerStateRepositoryProvider);

    Future<void> write(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update learner state: $error')),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(item.subtitle),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: marker.favorite ? 'Remove favorite' : 'Add favorite',
              onPressed: () => write(() async {
                (await repository.setFavorite(
                  identity,
                  favorite: !marker.favorite,
                )).getOrThrow();
              }),
              icon: Icon(
                marker.favorite ? Icons.favorite : Icons.favorite_border,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ContentMarkerChips(state: marker),
        if (item.type == ContentType.interview) ...[
          const SizedBox(height: 24),
          _InterviewAudioControls(item: item),
        ] else if (item.hasAudio) ...[
          const SizedBox(height: 24),
          _AudioPlaybackControls(item: item, marker: marker),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => write(() async {
                (await repository.setCompleted(
                  identity,
                  completed: !marker.completed,
                  lastRevisionSeen: item.revision,
                )).getOrThrow();
              }),
              icon: Icon(
                marker.completed ? Icons.restart_alt : Icons.check_circle,
              ),
              label: Text(
                marker.completed ? 'Mark incomplete' : 'Mark completed',
              ),
            ),
          ],
        ),
        if (marker.lastPositionMs case final position?
            when item.type != ContentType.interview) ...[
          const SizedBox(height: 12),
          Text(
            marker.lastRevisionSeen == item.revision
                ? 'Saved playback position: ${_formatDuration(position)}'
                : 'Saved playback position belongs to an older revision.',
          ),
        ],
        const SizedBox(height: 32),
        Text('Overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning content',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  item.type == ContentType.interview
                      ? 'Interview audio has independent question and sample-answer roles. Role clips use one active session and do not share a persisted resume position.'
                      : 'Audio playback uses the verified local asset pipeline. Completion of audio marks the item as listened; learning completion remains a separate learner action.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InterviewAudioControls extends ConsumerWidget {
  const _InterviewAudioControls({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(
      interviewAudioAvailableRolesProvider((
        content: ContentIdentity.fromItem(item),
        revision: item.revision,
      )),
    );

    return roles.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(value: 0),
        ),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Interview audio metadata unavailable: $error'),
        ),
      ),
      data: (availableRoles) {
        if (availableRoles.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No interview audio is published for this revision.'),
            ),
          );
        }

        final playback = ref.watch(interviewAudioClipStateProvider);
        return playback.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(value: 0),
            ),
          ),
          error: (error, stackTrace) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Interview audio unavailable: $error'),
            ),
          ),
          data: (state) => _buildControls(context, ref, state, availableRoles),
        );
      },
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    role_audio.RoleAudioClipState state,
    Set<ContentAudioRole> availableRoles,
  ) {
    final controller = ref.read(interviewAudioClipControllerProvider);
    final activeRole = state.role;
    final isResolving = state.phase == role_audio.AudioPlaybackPhase.resolving;
    final isPlaying = state.phase == role_audio.AudioPlaybackPhase.playing;
    final duration = state.durationMs;
    final position = state.positionMs;
    final progress = duration != null && duration > 0
        ? (position.clamp(0, duration) / duration).toDouble()
        : 0.0;

    Future<void> toggle(ContentAudioRole role) async {
      try {
        if (activeRole == role && isPlaying) {
          (await controller.pause()).getOrThrow();
        } else if (activeRole == role &&
            state.phase == role_audio.AudioPlaybackPhase.paused) {
          (await controller.resume()).getOrThrow();
        } else {
          (await controller.play(item, role)).getOrThrow();
        }
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Interview audio failed: $error')),
        );
      }
    }

    Widget roleButton(ContentAudioRole role, String label, IconData icon) {
      final active = activeRole == role;
      final playing = active && isPlaying;
      return FilledButton.tonalIcon(
        onPressed: isResolving ? null : () => toggle(role),
        icon: Icon(playing ? Icons.pause : icon),
        label: Text(playing ? 'Pause $label' : label),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.record_voice_over),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Interview audio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  duration == null
                      ? _formatDuration(position)
                      : '${_formatDuration(position)} / ${_formatDuration(duration)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (availableRoles.contains(ContentAudioRole.question))
                  roleButton(
                    ContentAudioRole.question,
                    'Question',
                    Icons.help_outline,
                  ),
                if (availableRoles.contains(ContentAudioRole.sampleAnswer))
                  roleButton(
                    ContentAudioRole.sampleAnswer,
                    'Sample answer',
                    Icons.chat_bubble_outline,
                  ),
                OutlinedButton.icon(
                  onPressed:
                      state.phase == role_audio.AudioPlaybackPhase.idle ||
                          state.phase == role_audio.AudioPlaybackPhase.stopped
                      ? null
                      : () async {
                          try {
                            (await controller.stop()).getOrThrow();
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Interview audio failed: $error'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
            if (state.failure case final failure?) ...[
              const SizedBox(height: 12),
              Text(
                failure.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AudioPlaybackControls extends ConsumerWidget {
  const _AudioPlaybackControls({required this.item, required this.marker});

  final ContentItem item;
  final ContentMarkerState marker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(audioPlaybackStateProvider);
    return playback.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(value: 0),
        ),
      ),
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Audio player unavailable: $error'),
        ),
      ),
      data: (state) => _buildControls(context, ref, state),
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    ContentPlaybackState state,
  ) {
    final identity = ContentIdentity.fromItem(item);
    final isCurrent = state.isCurrent(identity, item.revision);
    final phase = isCurrent ? state.phase : AudioPlaybackPhase.idle;
    final savedPosition = marker.lastRevisionSeen == item.revision
        ? marker.lastPositionMs ?? 0
        : 0;
    final position = isCurrent ? state.positionMs : savedPosition;
    final duration = isCurrent ? state.durationMs : null;
    final isPlaying = phase == AudioPlaybackPhase.playing;
    final isResolving = phase == AudioPlaybackPhase.resolving;
    final canControl =
        isCurrent &&
        (phase == AudioPlaybackPhase.playing ||
            phase == AudioPlaybackPhase.paused);

    Future<void> run(
      Future<void> Function(AudioPlaybackController controller) operation,
    ) async {
      try {
        final controller = ref.read(audioPlaybackControllerProvider);
        await operation(controller);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio playback failed: $error')),
        );
      }
    }

    final progress = duration != null && duration > 0
        ? (position.clamp(0, duration) / duration).toDouble()
        : 0.0;
    final failure = isCurrent ? state.failure : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.graphic_eq),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    duration == null
                        ? _formatDuration(position)
                        : '${_formatDuration(position)} / ${_formatDuration(duration)}',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: isResolving
                      ? null
                      : () => run((controller) async {
                          if (isPlaying) {
                            (await controller.pause()).getOrThrow();
                          } else if (phase == AudioPlaybackPhase.paused &&
                              isCurrent) {
                            (await controller.resume()).getOrThrow();
                          } else {
                            (await controller.play(
                              item,
                              learnerState: marker,
                            )).getOrThrow();
                          }
                        }),
                  icon: isResolving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    isResolving
                        ? 'Preparing'
                        : isPlaying
                        ? 'Pause'
                        : phase == AudioPlaybackPhase.completed
                        ? 'Replay'
                        : 'Play',
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Back 10 seconds',
                  onPressed: canControl
                      ? () => run((controller) async {
                          (await controller.seek(
                            position - 10000,
                          )).getOrThrow();
                        })
                      : null,
                  icon: const Icon(Icons.replay_10),
                ),
                IconButton.filledTonal(
                  tooltip: 'Forward 10 seconds',
                  onPressed: canControl
                      ? () => run((controller) async {
                          (await controller.seek(
                            position + 10000,
                          )).getOrThrow();
                        })
                      : null,
                  icon: const Icon(Icons.forward_10),
                ),
                OutlinedButton.icon(
                  onPressed: canControl
                      ? () => run((controller) async {
                          (await controller.stop()).getOrThrow();
                        })
                      : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ],
            ),
            if (failure != null) ...[
              const SizedBox(height: 12),
              Text(
                failure.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int milliseconds) {
  final totalSeconds = milliseconds.clamp(0, 1 << 31) ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
