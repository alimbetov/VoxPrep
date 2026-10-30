import '../../domain/content_identity.dart';
import '../../domain/content_marker_state.dart';
import '../result/result.dart';

abstract interface class LearnerStateRepository {
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers();

  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  });

  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  });

  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  });

  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  });
}
