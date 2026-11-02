import '../access/access_snapshot.dart';
import '../result/result.dart';

abstract interface class AccessSnapshotRepository {
  Future<Result<AccessSnapshot?>> read();

  Future<Result<void>> replace(AccessSnapshot snapshot);
}
