import '../content_delivery/content_manifest.dart';
import '../result/result.dart';

/// Stages non-pack resources owned by one immutable publication snapshot.
///
/// Implementations may cache immutable payloads before the root switch, but
/// learner visibility must remain fenced by the CURRENT root contentVersion.
abstract interface class PublicationSnapshotStager {
  Future<Result<void>> stage(RootContentManifest target);
}
