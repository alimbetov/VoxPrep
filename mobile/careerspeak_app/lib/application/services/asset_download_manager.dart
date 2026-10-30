import '../content_delivery/content_manifest.dart';
import '../ports/asset_byte_source.dart';
import '../ports/asset_file_store.dart';
import '../result/result.dart';

typedef AssetRetryDelay = Future<void> Function(Duration duration);

final class AssetDownloadOutcome {
  const AssetDownloadOutcome({required this.localPath, required this.reused});

  final String localPath;
  final bool reused;
}

final class AssetDownloadManager {
  factory AssetDownloadManager({
    required AssetByteSource source,
    required AssetFileStore store,
    int maxAttempts = 3,
    AssetRetryDelay? delay,
  }) {
    return AssetDownloadManager._(
      source,
      store,
      _requireAttempts(maxAttempts),
      delay ?? Future<void>.delayed,
    );
  }

  AssetDownloadManager._(
    this._source,
    this._store,
    this._maxAttempts,
    this._delay,
  );

  final AssetByteSource _source;
  final AssetFileStore _store;
  final int _maxAttempts;
  final AssetRetryDelay _delay;

  Future<Result<AssetDownloadOutcome>> ensureLocal(
    ManifestAssetDescriptor asset,
  ) async {
    final local = await _store.findVerified(asset);
    if (local case FailureResult<String?>(:final failure)) {
      return FailureResult(failure);
    }
    final existing = (local as Success<String?>).value;
    if (existing != null) {
      return Success(AssetDownloadOutcome(localPath: existing, reused: true));
    }

    for (var attempt = 1; attempt <= _maxAttempts; attempt += 1) {
      final opened = await _source.open(asset);
      if (opened case FailureResult<AssetByteStream>(:final failure)) {
        if (!_shouldRetry(failure, attempt)) return FailureResult(failure);
        await _delay(_retryDelay(attempt));
        continue;
      }

      final stream = (opened as Success<AssetByteStream>).value;
      final contentLength = stream.contentLength;
      if (contentLength != null && contentLength != asset.sizeBytes) {
        return FailureResult(
          ApplicationFailure(
            code: 'ASSET_SIZE_MISMATCH',
            message: 'The asset response size does not match its manifest.',
            details: <String, Object?>{
              'assetId': asset.assetId,
              'expectedSize': asset.sizeBytes,
              'actualSize': contentLength,
            },
          ),
        );
      }

      final written = await _store.writeVerified(
        asset: asset,
        bytes: stream.bytes,
      );
      if (written case Success<String>(:final value)) {
        return Success(AssetDownloadOutcome(localPath: value, reused: false));
      }

      final failure = (written as FailureResult<String>).failure;
      if (!_shouldRetry(failure, attempt)) return FailureResult(failure);
      await _delay(_retryDelay(attempt));
    }

    throw StateError('Asset download retry loop exited unexpectedly.');
  }

  bool _shouldRetry(ApplicationFailure failure, int attempt) =>
      failure.retryable && attempt < _maxAttempts;

  static Duration _retryDelay(int completedAttempt) {
    final multiplier = 1 << (completedAttempt - 1);
    return Duration(milliseconds: 200 * multiplier);
  }

  static int _requireAttempts(int value) {
    if (value < 1) {
      throw ArgumentError.value(value, 'maxAttempts', 'must be at least 1');
    }
    return value;
  }
}
